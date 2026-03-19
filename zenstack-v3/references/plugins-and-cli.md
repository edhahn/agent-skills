# ZenStack v3 Plugins & CLI Reference

## CLI

The CLI is in `@zenstackhq/cli`. Invoked as `zen` or `zenstack` (equivalent).

### Installation

```bash
npm install --save-dev @zenstackhq/cli
npm install @zenstackhq/schema @zenstackhq/orm
```

### Core Commands

#### `zen generate`

Compiles ZModel schema into TypeScript code (in `zenstack/` folder). This is the primary command. Generated code supports both dev-time typing and runtime schema access.

```bash
npx zen generate
```

#### `zen db push`

Push schema changes to database without creating migration files. **Dev/test only.**

```bash
npx zen db push
```

#### `zen db pull`

Introspect database and generate ZModel schema from it.

#### `zen migrate dev`

Create migration file from schema changes and apply to DB. **Dev only.**

```bash
npx zen migrate dev
npx zen migrate dev --create-only  # create empty migration for manual implementation
```

#### `zen migrate deploy`

Apply pending migrations. Use in **production deployment pipelines**.

```bash
npx zen migrate deploy
```

#### `zen migrate reset`

Drop all tables and reapply all migrations. **Dev/test only.**

#### `zen migrate status`

Show migration status (applied vs pending).

#### `zen migrate resolve`

Mark migration as applied/rolled-back without changing DB.

### Typical package.json Scripts

```json
{
  "scripts": {
    "generate": "zen generate",
    "db:push": "zen db push",
    "migrate:dev": "zen migrate dev",
    "migrate:deploy": "zen migrate deploy"
  }
}
```

## Migration Engine

Built on top of **Prisma Migrate** — ZenStack generates a Prisma schema from ZModel, then runs Prisma Migrate commands. Benefits:
- Mature, reliable migration tool
- Backward compatible with existing Prisma migration scripts
- Just swap `prisma` CLI with `zen`

### Development Workflow

1. Edit ZModel schema
2. `zen db push` to test changes
3. `zen migrate dev` to create migration file
4. Review, adjust, commit migration file

### Production Workflow

Run `zen migrate deploy` in deployment pipeline.

## Plugin System (Preview)

### Schema-Level Plugins

Declared in ZModel:

```zmodel
plugin policy {
  provider = '@zenstackhq/plugin-policy'
}

plugin prisma {
  provider = '@core/prisma'
  output   = '../prisma/schema.prisma'
}

plugin typescript {
  provider = '@core/typescript'
  output   = '../generated'
}
```

Plugin declaration:
- **name**: unique identifier
- **provider**: built-in (`@core/...`), local module, or npm package
- **options**: plugin-specific config (e.g., `output`)

### Built-in Plugins

#### `@core/typescript`

Runs automatically. Generates TypeScript code from ZModel. You can explicitly declare it to customize output path.

#### `@core/prisma`

Generates a Prisma schema from ZModel. **Not needed for ORM runtime** — only for running Prisma generators or tools that consume Prisma schemas.

```zmodel
plugin prisma {
  provider = '@core/prisma'
  output   = '../prisma/schema.prisma'
}
```

#### `@zenstackhq/plugin-policy`

Provides access control. Adds `@@allow`, `@@deny`, `auth()`, etc. See access-control.md.

### Runtime Plugins

Installed via `$use()` on the ORM client. Returns new immutable client.

```typescript
const db = new ZenStackClient(schema, { ... });
const enhanced = db.$use(myPlugin);
const stripped = enhanced.$unuseAll();
```

#### Defining Runtime Plugins

Three equivalent ways:

```typescript
// Object literal
db.$use({ id: 'my-plugin', ... });

// Class
class MyPlugin implements RuntimePlugin {
  readonly id = 'my-plugin';
  // ...
}
db.$use(new MyPlugin());

// Helper function
import { definePlugin } from '@zenstackhq/orm';
db.$use(definePlugin({ id: 'my-plugin', ... }));
```

#### Plugin Hook Types

1. **Query API Hooks** — intercept ORM operations (before/after/block)
2. **Entity Mutation Hooks** — react to create/update/delete events
3. **Kysely Query Hooks** — transform SQL AST before execution (powerful, use with care)

#### Extending ORM Client API

Plugins can add:
- New methods/properties to the client
- New properties to query arguments

Example: a cache plugin adding `$invalidateCache()` and `cache` option to read queries.

### Plugin Capabilities Summary

| Level | What It Can Do |
|-------|---------------|
| Schema | Contribute attributes/functions, generate code |
| CLI | Extend CLI commands |
| Runtime | Hook into CRUD lifecycle, extend client API |
