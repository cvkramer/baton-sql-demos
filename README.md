# Baton-SQL Demo Environments

Demo configurations for showcasing baton-sql with different database backends. Includes **provisioning support** for granting and revoking group memberships.

## Quick Start

```bash
# PostgreSQL (fastest to start)
cd postgres && podman-compose up -d

# MySQL
cd mysql && podman-compose up -d

# MariaDB
cd mysql && podman-compose -f docker-compose.mariadb.yml up -d

# SQL Server
cd sqlserver && podman-compose up -d

# Oracle (slowest - ~3 min startup)
cd oracle && podman-compose up -d

# Vertica
cd vertica && podman-compose up -d
```

## What Gets Created

Each demo creates:
- **6 users**: Alice, Bob, Carol, David, Eve, Frank (with varying statuses)
- **5 groups**: engineering, sales, admin, finance, hr
- **8 memberships**: Various user-to-group assignments

## Features

### Sync (Read)
- Syncs users with status mapping (active/inactive/suspended)
- Syncs groups with descriptions
- Syncs group membership grants

### Provisioning (Write)
- **Grant**: Add user to group (`INSERT` with idempotent handling)
- **Revoke**: Remove user from group (`DELETE`)

Each database has its own `config.yaml` with database-specific SQL syntax:
- PostgreSQL: `ON CONFLICT DO NOTHING`
- MySQL/MariaDB: `INSERT IGNORE`
- SQL Server: `IF NOT EXISTS ... INSERT`
- Oracle: `MERGE INTO ... WHEN NOT MATCHED`
- Vertica: `MERGE INTO ... WHEN NOT MATCHED`

## Viewing Results

```bash
# Install baton CLI if needed
brew install conductorone/tap/baton

# View synced resources
baton resources -f postgres/output/sync.c1z

# View grants (who has access to what)
baton grants -f postgres/output/sync.c1z

# View entitlements (what can be granted)
baton entitlements -f postgres/output/sync.c1z
```

## Directory Structure

```
baton-sql-demos/
├── README.md
├── demo.sh                      # Helper script
├── shared/
│   └── config.yaml              # Generic config template
├── postgres/
│   ├── docker-compose.yml
│   ├── config.yaml              # PostgreSQL-specific queries
│   ├── init.sql
│   └── output/
├── mysql/
│   ├── docker-compose.yml
│   ├── docker-compose.mariadb.yml
│   ├── config.yaml              # MySQL/MariaDB-specific queries
│   ├── init.sql
│   └── output/
├── sqlserver/
│   ├── docker-compose.yml
│   ├── config.yaml              # SQL Server-specific queries
│   ├── init.sql
│   └── output/
├── oracle/
│   ├── docker-compose.yml
│   ├── config.yaml              # Oracle-specific queries
│   ├── init.sql
│   └── output/
└── vertica/
    ├── docker-compose.yml
    ├── config.yaml              # Vertica-specific queries
    ├── init.sql
    └── output/
```

## Database Connection Details

| Database   | Host      | Port | User   | Password  | Database |
|------------|-----------|------|--------|-----------|----------|
| PostgreSQL | localhost | 5432 | baton  | demo123   | demo     |
| MySQL      | localhost | 3306 | baton  | demo123   | demo     |
| MariaDB    | localhost | 3306 | baton  | demo123   | demo     |
| SQL Server | localhost | 1433 | sa     | Demo123!  | demo     |
| Oracle     | localhost | 1521 | system | Demo123   | XEPDB1   |
| Vertica    | localhost | 5433 | dbadmin| (empty)   | docker   |

## Manual Database Access

```bash
# PostgreSQL
podman exec -it postgres_postgres_1 psql -U baton -d demo

# MySQL
podman exec -it mysql_mysql_1 mysql -ubaton -pdemo123 demo

# SQL Server
podman exec -it sqlserver_sqlserver_1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'Demo123!' -C -d demo

# Oracle
podman exec -it oracle_oracle_1 sqlplus system/Demo123@localhost/XEPDB1

# Vertica
podman exec -it vertica_vertica_1 /opt/vertica/bin/vsql -U dbadmin
```

## Testing Provisioning

To test grant/revoke operations:

1. **Run a sync** to populate ConductorOne with resources
2. **Use ConductorOne UI** or API to request access (grant a user to a group)
3. **Check the database** to verify the membership was created:
   ```sql
   SELECT * FROM group_memberships;
   ```

### Manual provisioning test via baton CLI

```bash
# Grant: Add Eve to admin group
baton grants create \
  --file postgres/output/sync.c1z \
  --entitlement "group:3:member" \
  --principal "user:5"

# Revoke: Remove Eve from admin group
baton grants delete \
  --file postgres/output/sync.c1z \
  --grant-id "<grant-id-from-above>"
```

## Re-running Sync

```bash
# Trigger another sync (one-shot mode)
cd postgres
podman-compose run --rm baton-sql

# Or restart the baton-sql service
podman-compose restart baton-sql
```

## Cleanup

```bash
# Stop and remove containers + volumes
cd postgres && podman-compose down -v

# Remove all demos
for dir in postgres mysql sqlserver oracle; do
  cd $dir && podman-compose down -v && cd ..
done
```

## Customizing the Demo

### Add more users/groups

Edit the `init.sql` file for your database, then recreate:

```bash
podman-compose down -v
podman-compose up -d
```

### Modify sync/provisioning queries

Edit the `config.yaml` in each database directory. Each config includes:
- `users` - User sync query and field mappings
- `groups` - Group sync query and field mappings
- `groups.static_entitlements` - Entitlements that can be granted
- `groups.static_entitlements[].provisioning` - Grant/revoke SQL
- `groups.grants` - Query to discover existing grants

### Add roles/permissions

Extend the schema with a `roles` table and update `config.yaml`:

```yaml
roles:
  query: |
    SELECT id, name, description FROM roles
  id: id
  displayName: name

  static_entitlements:
    - id: "assigned"
      display_name: "Assigned"
      description: "Role assignment"
      purpose: "permission"
      grantable_to:
        - "user"

      provisioning:
        vars:
          user_id: "principal.ID"
          role_id: "resource.ID"
        grant:
          queries:
            - |
              INSERT INTO user_roles (user_id, role_id)
              VALUES (?<user_id>, ?<role_id>)
              ON CONFLICT DO NOTHING
        revoke:
          queries:
            - |
              DELETE FROM user_roles
              WHERE user_id = ?<user_id> AND role_id = ?<role_id>

  grants:
    query: |
      SELECT role_id, user_id, 'assigned' as entitlement
      FROM user_roles
    entitlement: entitlement
    principalId: user_id
    principalType: user
    resourceId: role_id
```

## Notes

- **Oracle**: Requires accepting Oracle's license. You may need to log in to `container-registry.oracle.com` first.
- **SQL Server**: Uses the `sa` account for simplicity. In production, create a dedicated user.
- **Ports**: Each database uses its standard port. Only run one database type at a time, or change ports in compose files.
- **Provisioning flag**: The `--provisioning` flag is already set in the compose files. Without it, grant/revoke operations won't work.
- **Vertica**: Uses `cjonesy/docker-vertica:latest` (Vertica 9.2.1). Runs with `--platform linux/amd64` for Apple Silicon (no ARM image available).
