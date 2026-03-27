# Baton-SQL Demo Environments

Demo configurations for showcasing baton-sql with different database backends.

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
```

## What Gets Created

Each demo creates:
- **6 users**: Alice, Bob, Carol, David, Eve, Frank (with varying statuses)
- **5 groups**: engineering, sales, admin, finance, hr
- **8 memberships**: Various user-to-group assignments

## Viewing Results

After baton-sql runs, check the sync output:

```bash
# Install baton CLI if needed
brew install conductorone/tap/baton

# View synced resources
baton resources -f postgres/output/sync.c1z

# View grants (who has access to what)
baton grants -f postgres/output/sync.c1z
```

## Directory Structure

```
baton-sql-demos/
├── shared/
│   └── config.yaml          # Shared baton-sql config (queries)
├── postgres/
│   ├── docker-compose.yml
│   ├── init.sql
│   └── output/              # Created on first run
├── mysql/
│   ├── docker-compose.yml
│   ├── docker-compose.mariadb.yml
│   ├── init.sql
│   └── output/
├── sqlserver/
│   ├── docker-compose.yml
│   ├── init.sql
│   └── output/
└── oracle/
    ├── docker-compose.yml
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

### Modify sync queries

Edit `shared/config.yaml` to change what gets synced. The config supports:
- Custom user queries with field mappings
- Custom group queries
- Multiple grant types (membership, ownership, etc.)

### Add roles/permissions

Extend the schema with a `roles` table and update `config.yaml`:

```yaml
roles:
  query: |
    SELECT id, name, description FROM roles
  id: id
  displayName: name

grants:
  - resourceType: role
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
