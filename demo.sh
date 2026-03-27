#!/bin/bash
# Demo helper script for baton-sql demos

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo "Usage: $0 <command> <database>"
    echo ""
    echo "Databases: postgres, mysql, mariadb, sqlserver, oracle, vertica"
    echo ""
    echo "Commands:"
    echo "  up       - Start the demo environment"
    echo "  down     - Stop and remove containers"
    echo "  clean    - Stop, remove containers AND volumes"
    echo "  logs     - Show logs from all services"
    echo "  sync     - Run baton-sql sync manually"
    echo "  shell    - Open database shell"
    echo "  show     - Show synced resources and grants"
    echo "  status   - Show container status"
    echo ""
    echo "Examples:"
    echo "  $0 up postgres      # Start PostgreSQL demo"
    echo "  $0 shell mysql      # Open MySQL shell"
    echo "  $0 show postgres    # View sync results"
    exit 1
}

[[ $# -lt 2 ]] && usage

COMMAND=$1
DATABASE=$2

# Determine compose file and directory
case $DATABASE in
    postgres)
        DIR="$SCRIPT_DIR/postgres"
        COMPOSE_FILE="docker-compose.yml"
        ;;
    mysql)
        DIR="$SCRIPT_DIR/mysql"
        COMPOSE_FILE="docker-compose.yml"
        ;;
    mariadb)
        DIR="$SCRIPT_DIR/mysql"
        COMPOSE_FILE="docker-compose.mariadb.yml"
        ;;
    sqlserver)
        DIR="$SCRIPT_DIR/sqlserver"
        COMPOSE_FILE="docker-compose.yml"
        ;;
    oracle)
        DIR="$SCRIPT_DIR/oracle"
        COMPOSE_FILE="docker-compose.yml"
        ;;
    vertica)
        DIR="$SCRIPT_DIR/vertica"
        COMPOSE_FILE="docker-compose.yml"
        ;;
    *)
        echo "Unknown database: $DATABASE"
        usage
        ;;
esac

cd "$DIR"

case $COMMAND in
    up)
        echo "Starting $DATABASE demo..."
        podman-compose -f "$COMPOSE_FILE" up -d
        echo ""
        echo "Waiting for services to be healthy..."
        sleep 5
        podman-compose -f "$COMPOSE_FILE" ps
        echo ""
        echo "Check sync output with: $0 show $DATABASE"
        ;;
    down)
        echo "Stopping $DATABASE demo..."
        podman-compose -f "$COMPOSE_FILE" down
        ;;
    clean)
        echo "Cleaning $DATABASE demo (including volumes)..."
        podman-compose -f "$COMPOSE_FILE" down -v
        rm -rf output/
        ;;
    logs)
        podman-compose -f "$COMPOSE_FILE" logs -f
        ;;
    sync)
        echo "Running baton-sql sync..."
        podman-compose -f "$COMPOSE_FILE" run --rm baton-sql
        ;;
    shell)
        case $DATABASE in
            postgres)
                podman-compose -f "$COMPOSE_FILE" exec postgres psql -U baton -d demo
                ;;
            mysql)
                podman-compose -f "$COMPOSE_FILE" exec mysql mysql -ubaton -pdemo123 demo
                ;;
            mariadb)
                podman-compose -f "$COMPOSE_FILE" exec mariadb mysql -ubaton -pdemo123 demo
                ;;
            sqlserver)
                podman-compose -f "$COMPOSE_FILE" exec sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'Demo123!' -C -d demo
                ;;
            oracle)
                podman-compose -f "$COMPOSE_FILE" exec oracle sqlplus system/Demo123@localhost/XEPDB1
                ;;
            vertica)
                podman-compose -f "$COMPOSE_FILE" exec vertica /opt/vertica/bin/vsql -U dbadmin
                ;;
        esac
        ;;
    show)
        OUTPUT_FILE="$DIR/output/sync.c1z"
        if [[ ! -f "$OUTPUT_FILE" ]]; then
            echo "No sync output found. Run '$0 up $DATABASE' first and wait for sync to complete."
            exit 1
        fi
        echo "=== Resources ==="
        baton resources -f "$OUTPUT_FILE"
        echo ""
        echo "=== Grants ==="
        baton grants -f "$OUTPUT_FILE"
        ;;
    status)
        podman-compose -f "$COMPOSE_FILE" ps
        ;;
    *)
        echo "Unknown command: $COMMAND"
        usage
        ;;
esac
