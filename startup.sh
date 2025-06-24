#!/bin/sh

echo "Starting Akephaloi CMS..."

# Wait for system to be ready
echo "Waiting for system to be ready..."
sleep 3

# Check if database file exists, if not create it
DB_PATH="/app/resources/database/akephaloi.db"
if [ ! -f "$DB_PATH" ]; then
    echo "Database not found, will be created on first query..."
fi

# Start the server first
echo "Starting ColdBox server..."
box server start port=8080 host=0.0.0.0 openbrowser=false --daemon

# Wait for server to start
echo "Waiting for server to start..."
sleep 10

# Initialize database if needed
echo "Initializing database..."
box exec "
try {
    writeOutput('Checking database connection...');
    queryExecute('SELECT 1', {}, {datasource='akephaloi'});
    
    // Check if tables exist
    try {
        queryExecute('SELECT COUNT(*) FROM users LIMIT 1', {}, {datasource='akephaloi'});
        writeOutput('Database already initialized');
    } catch(any e) {
        writeOutput('Creating database schema...');
        var sqlContent = fileRead('/app/resources/database/migrations/001_initial_schema.sql');
        queryExecute(sqlContent, {}, {datasource='akephaloi'});
        writeOutput('Database schema created successfully');
    }
} catch(any e) {
    writeOutput('Database error: ' & e.message);
    writeOutput('Error detail: ' & e.detail);
}
"

echo "System ready! Server running on port 8080"

# Keep the container running by following server logs
tail -f /app/logs/*.log 2>/dev/null || sleep infinity
