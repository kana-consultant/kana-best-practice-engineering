---
name: kana-rust-backend-best-practice
description: Reference guide for building a Rust clean-architecture backend with Axum, SeaORM, Argon2, JWT, and sea-orm-migration. Use when scaffolding a new Rust service, adding a feature (domain + use-case + repository + handler), or reviewing Rust code against the axum-clean-architecture reference layout.
---

# Axum Clean Architecture Skill

Reference stack (see `../axum-clean-architecture`):

| Layer | Tech |
|---|---|
| HTTP framework | Axum 0.8 |
| ORM | SeaORM 1.1 (PostgreSQL via sqlx + rustls) |
| Migrations | sea-orm-migration |
| Auth | Argon2 (password hashing) + jsonwebtoken (JWT) |
| Validation | zod-rs (schema-driven, mirrors Zod) |
| Pagination | paginator-rs + paginator-sea-orm + paginator-axum |
| Observability | tracing + tracing-subscriber |
| Middleware | tower-http (CORS, TraceLayer) |
| Runtime | Tokio (full features) |
| Error handling | anyhow (app-level), typed domain errors |

---

## 0. Workspace layout

```
axum-clean-architecture/
├── Cargo.toml               # workspace, resolver = "3"
├── apps/
│   ├── iam/                 # core domain library (lib crate)
│   │   └── src/
│   │       ├── domain/      # entities, repository traits, domain errors
│   │       ├── application/ # use cases + port traits
│   │       ├── infrastructure/ # SeaORM repos + auth services
│   │       └── presentation/   # Axum handlers, DTOs, middleware, state
│   ├── gateway/             # binary — assembles router, runs server
│   └── bootstrap/           # binary — seeds permissions/roles/admin
├── .config/                 # AppServer, database/env helpers
└── .migrations/             # sea-orm-migration crate
```

The `iam` app is a **library crate**. `gateway` and `bootstrap` depend on it.

---

## 1. Dependency rules (strictly enforced)

```
presentation → application → domain
infrastructure → domain        (implements domain traits)
presentation → infrastructure  (only to wire AppState)
```

- Domain has **zero** external crate dependencies beyond `uuid`, `chrono`.
- Use cases depend only on port traits — never on concrete infrastructure types.
- Presentation instantiates use cases from `AppState` on every request; use cases are not stored.

---

## 2. Domain layer

### Entity pattern

Plain Rust structs — no derives beyond what domain logic needs. No ORM annotations.

```rust
// domain/user/entity.rs
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub password_hash: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

pub struct NewUser {
    pub id: Uuid,
    pub email: String,
    pub password_hash: String,
}

#[derive(Default)]
pub struct UserPatch {
    pub email: Option<String>,
    pub password_hash: Option<String>,
}
```

### Repository trait pattern

Use `impl Future` in trait methods (Rust 2024 edition, no `async_trait` needed).
Always `Send + Sync` on the trait.

```rust
// domain/user/repository.rs
pub trait UserRepository: Send + Sync {
    fn find_by_id(&self, id: Uuid)
        -> impl Future<Output = Result<Option<User>, RepositoryError>> + Send;
    fn find_by_email(&self, email: &str)
        -> impl Future<Output = Result<Option<User>, RepositoryError>> + Send;
    fn create(&self, user: NewUser)
        -> impl Future<Output = Result<User, RepositoryError>> + Send;
    fn update(&self, id: Uuid, patch: UserPatch)
        -> impl Future<Output = Result<User, RepositoryError>> + Send;
    fn delete(&self, id: Uuid)
        -> impl Future<Output = Result<(), RepositoryError>> + Send;
    fn list(&self, params: &PaginationParams)
        -> impl Future<Output = Result<PaginatorResponse<User>, RepositoryError>> + Send;
}
```

### Shared RepositoryError (lives in domain)

```rust
pub enum RepositoryError {
    NotFound,
    Conflict(String),
    Database(String),
}
```

### Domain errors

Per-aggregate. `AuthError` lives in `domain/auth/errors.rs`:

```rust
pub enum AuthError {
    InvalidCredentials,
    EmailAlreadyExists,
    UserNotFound,
    PasswordHashFailed(String),
    PasswordVerificationFailed(String),
    TokenGenerationFailed(String),
    InvalidToken(String),
    RepositoryError(String),
}
```

---

## 3. Application layer

### Port traits (interfaces for external services)

```rust
// application/auth/ports/password.rs
pub trait PasswordService: Send + Sync {
    fn hash(&self, password: &str)
        -> impl Future<Output = Result<String, PasswordError>> + Send;
    fn verify(&self, password: &str, hash: &str)
        -> impl Future<Output = Result<bool, PasswordError>> + Send;
}
```

```rust
// application/auth/ports/token.rs
pub trait TokenService: Send + Sync {
    fn generate_auth_tokens(&self, sub: &str)
        -> impl Future<Output = Result<(String, String), TokenError>> + Send;
    fn verify_access_token(&self, token: &str)
        -> Result<String, TokenError>;
}
```

### Use case pattern

Generic over port traits and repository traits. Constructed in the handler, not stored.

```rust
// application/user/use_cases/create.rs
pub struct CreateUserCommand { pub email: String, pub password: String }

pub struct CreateUserUseCase<P, R> {
    password_service: P,
    user_repository: R,
}

impl<P: PasswordService, R: UserRepository> CreateUserUseCase<P, R> {
    pub fn new(password_service: P, user_repository: R) -> Self { ... }

    pub async fn execute(&self, cmd: CreateUserCommand) -> Result<User, AuthError> {
        // 1. guard: check uniqueness
        // 2. hash password via port
        // 3. create domain entity with Uuid::new_v4()
        // 4. persist via repository
        // 5. log + return
        info!(user_id = %user.id, "user created");
        Ok(user)
    }
}
```

### Use case naming convention

| File | Struct | Command/Query |
|---|---|---|
| `create.rs` | `CreateXxxUseCase` | `CreateXxxCommand` |
| `update.rs` | `UpdateXxxUseCase` | `UpdateXxxCommand` |
| `delete.rs` | `DeleteXxxUseCase` | `DeleteXxxCommand` |
| `detail.rs` | `XxxDetailUseCase` | `XxxDetailQuery` |
| `list.rs` | `ListXxxsUseCase` | takes `&PaginationParams` |

---

## 4. Infrastructure layer

### SeaORM repository implementation

```rust
// infrastructure/repository/user.rs
#[derive(Clone)]
pub struct SeaOrmUserRepository { db: DatabaseConnection }

// Convert ORM Model → domain entity here (not in domain)
impl From<Model> for User { ... }

// Map DbErr → RepositoryError
fn map_db_err(e: DbErr) -> RepositoryError {
    match e {
        DbErr::RecordNotFound(_) => RepositoryError::NotFound,
        other => { error!(error = %other, "database operation failed"); RepositoryError::Database(other.to_string()) }
    }
}

impl UserRepository for SeaOrmUserRepository {
    async fn create(&self, user: NewUser) -> Result<User, RepositoryError> {
        let model = ActiveModel {
            id: Set(user.id),
            email: Set(user.email),
            password_hash: Set(user.password_hash),
            created_at: Set(now),
            updated_at: Set(now),
        };
        let inserted = model.insert(&self.db).await.map_err(|e| match e {
            DbErr::Exec(ref msg) | DbErr::Query(ref msg)
                if msg.to_string().contains("unique") =>
                RepositoryError::Conflict("email already exists".into()),
            other => RepositoryError::Database(other.to_string()),
        })?;
        Ok(User::from(inserted))
    }
}
```

Pagination uses `paginator-sea-orm`:

```rust
let response = UserEntity::find()
    .paginate_with(&self.db, params)
    .await
    .map_err(|e| RepositoryError::Database(e.to_string()))?;
let mapped: Vec<User> = response.data.into_iter().map(User::from).collect();
Ok(PaginatorResponse { data: mapped, meta: response.meta })
```

### Auth services

- `Argon2PasswordService`: uses `spawn_blocking` for CPU-bound hashing, `SaltString::generate(OsRng)`.
- `JwtTokenService`: stores `secret: Vec<u8>`, generates separate access/refresh tokens with a `type` claim. `verify_access_token` checks `claims.token_type == "access"`.

### SeaORM entities (ORM models)

Live in `infrastructure/repository/entities/`. One file per table. Junction tables (`user_role`, `role_permission`) have composite primary keys. Timestamps use `DateTimeWithTimeZone`.

---

## 5. Presentation layer

### AppState

Concrete types only — no trait objects. Cheap to clone because `DatabaseConnection` is internally Arc-backed.

```rust
#[derive(Clone)]
pub struct AppState {
    pub password_service: Argon2PasswordService,
    pub token_service: JwtTokenService,
    pub user_repository: SeaOrmUserRepository,
    pub role_repository: SeaOrmRoleRepository,
    pub permission_repository: SeaOrmPermissionRepository,
}
```

Injected via `Extension(state)` on every handler. Use cases are constructed inside handlers.

### AppError

```rust
pub enum AppError { BadRequest(String), Unauthorized, Forbidden, NotFound, Conflict(String), Internal(String) }

impl IntoResponse for AppError { /* maps to HTTP status + JSON { "error": "..." } */ }

impl From<AuthError> for AppError { ... }
impl From<RepositoryError> for AppError { ... }
impl From<TokenError> for AppError { ... }
```

Internal errors are logged with `tracing::error!` before returning a generic 500 message.

### Handler pattern

```rust
#[instrument(skip_all, fields(actor = %actor.id, email = %req.email))]
pub async fn create(
    Extension(state): Extension<AppState>,
    Extension(actor): Extension<AuthenticatedUser>,
    Json(req): Json<CreateUserRequest>,
) -> Result<(StatusCode, Json<UserResponse>), AppError> {
    let use_case = CreateUserUseCase::new(
        state.password_service.clone(),
        state.user_repository.clone(),
    );
    let user = use_case.execute(req.into()).await?;
    Ok((StatusCode::CREATED, Json(user.into())))
}
```

Rules:
- Always `#[instrument(skip_all, fields(...))]` on every handler.
- Use `?` to propagate `AppError` (via `From` impls).
- `201 CREATED` for `POST`, `204 NO_CONTENT` for `DELETE`, `200 OK` for everything else.
- Pagination handlers return `PaginatedJson<Dto>` via `paginator-axum`.

### DTO pattern

```rust
#[derive(Debug, Serialize, Deserialize, ZodSchema)]
pub struct CreateUserRequest {
    #[zod(email)]
    pub email: String,
    #[zod(min_length(8), max_length(128))]
    pub password: String,
}

impl From<CreateUserRequest> for CreateUserCommand { ... }

#[derive(Debug, Serialize)]
pub struct UserResponse { pub id: Uuid, pub email: String, pub created_at: DateTime<Utc>, pub updated_at: DateTime<Utc> }

impl From<User> for UserResponse { ... }
```

- Request structs: `Deserialize + ZodSchema`. Use `#[zod(...)]` for field-level validation.
- Response structs: `Serialize` only. Never expose `password_hash`.
- Conversions: `impl From<Request> for Command` and `impl From<DomainEntity> for Response`.

### Middleware

**Auth middleware** (`presentation/middleware/auth.rs`):
- Extracts `Bearer <token>` from `Authorization` header.
- Calls `state.token_service.verify_access_token(token)`.
- Inserts `AuthenticatedUser { id: Uuid }` into request extensions.

**Permission check** (`presentation/middleware/permission.rs`):
- Called inline from handlers: `ensure_permission(&state, &actor, "users:write").await?`.
- Queries `permission_repository.find_for_user(actor.id)` and checks by name.

### Router assembly

```rust
pub fn build_router(state: AppState) -> Router {
    Router::new()
        .nest("/auth", auth::router())
        .nest("/me", me::router())
        .nest("/users", user::router())
        .nest("/roles", role::router())
        .nest("/permissions", permission::router())
        .layer(Extension(state))
}
```

Gateway nests the IAM router at `/api/v1/iam` and adds a health check at `/`.

---

## 6. Migrations (sea-orm-migration)

```rust
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager.create_table(
            Table::create()
                .table(Users::Table)
                .if_not_exists()
                .col(ColumnDef::new(Users::Id).uuid().not_null().primary_key())
                .col(ColumnDef::new(Users::Email).string().not_null().unique_key())
                ...
                .to_owned(),
        ).await
    }
    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager.drop_table(Table::drop().table(Users::Table).to_owned()).await
    }
}

#[derive(DeriveIden)]
pub enum Users { Table, Id, Email, PasswordHash, CreatedAt, UpdatedAt }
```

Naming convention: `m{YYYYMMDD}_{6-digit-seq}_{description}.rs`, e.g. `m20260413_000001_create_users.rs`.

---

## 7. Bootstrap pattern

A separate `bootstrap` binary seeds idempotent system data (permissions, roles, admin user):

```rust
// Check existence before inserting — fully idempotent
if permission_repo.find_by_name("rbac:manage").await?.is_none() {
    permission_repo.create(...).await?;
}
```

Standard permissions:
- `rbac:manage`, `users:read`, `users:write`, `roles:read`, `roles:write`, `permissions:read`, `permissions:write`

---

## 8. Adding a new aggregate (checklist)

1. **Domain**: `domain/{name}/entity.rs` (entity + NewXxx + XxxPatch), `domain/{name}/repository.rs` (trait + errors), `domain/{name}/errors.rs` if needed.
2. **Application**: `application/{name}/mod.rs`, `application/{name}/use_cases/{create,update,delete,detail,list}.rs`.
3. **Infrastructure entity**: `infrastructure/repository/entities/{name}.rs` (SeaORM model).
4. **Infrastructure repo**: `infrastructure/repository/{name}.rs` (`From<Model>`, `impl XxxRepository for SeaOrmXxxRepository`).
5. **Add to AppState**: `{name}_repository: SeaOrmXxxRepository`.
6. **Presentation DTO**: `presentation/{name}/dto.rs` (Request + Response with `From` impls).
7. **Presentation handlers**: `presentation/{name}/handlers.rs` (`#[instrument]`, construct use case, return DTO).
8. **Presentation router**: `presentation/{name}/mod.rs` (define routes with `axum_route_macro` or `Router::new().route(...)`).
9. **Nest in `build_router`**.
10. **Migration**: new file in `.migrations/src/` following naming convention.
11. **Bootstrap**: seed any required initial data.

---

## 9. Key conventions

- Edition **2024** — use `impl Future` in traits, not `#[async_trait]`.
- All timestamps are `DateTime<Utc>` in domain; `DateTimeWithTimeZone` in SeaORM models; convert with `.with_timezone(&Utc)`.
- UUIDs generated with `Uuid::new_v4()` in the use case, not the repository.
- Unique-constraint conflicts detected via string match on `DbErr::Exec`/`DbErr::Query` containing `"unique"` — map to `RepositoryError::Conflict`.
- `tracing::instrument` on every handler; log user/actor IDs as structured fields.
- `warn!` for expected failures (wrong password, permission denied), `error!` for unexpected DB errors.
- Response structs never expose internal fields (`password_hash`, internal IDs from junction tables).
