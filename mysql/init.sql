-- MySQL/MariaDB init script for baton-sql demo

-- Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Groups table
CREATE TABLE groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Group memberships (many-to-many)
CREATE TABLE group_memberships (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    group_id INT NOT NULL,
    role VARCHAR(50) DEFAULT 'member',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_membership (user_id, group_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);

-- Sample data: Users
INSERT INTO users (email, first_name, last_name, status) VALUES
    ('alice@example.com', 'Alice', 'Anderson', 'active'),
    ('bob@example.com', 'Bob', 'Baker', 'active'),
    ('carol@example.com', 'Carol', 'Chen', 'active'),
    ('david@example.com', 'David', 'Davis', 'inactive'),
    ('eve@example.com', 'Eve', 'Edwards', 'active'),
    ('frank@example.com', 'Frank', 'Fisher', 'suspended');

-- Sample data: Groups
INSERT INTO groups (name, description) VALUES
    ('engineering', 'Engineering team'),
    ('sales', 'Sales department'),
    ('admin', 'System administrators'),
    ('finance', 'Finance and accounting'),
    ('hr', 'Human resources');

-- Sample data: Memberships
INSERT INTO group_memberships (user_id, group_id, role) VALUES
    (1, 1, 'member'),  -- Alice in engineering
    (1, 3, 'member'),  -- Alice in admin
    (2, 1, 'member'),  -- Bob in engineering
    (3, 2, 'member'),  -- Carol in sales
    (3, 4, 'member'),  -- Carol in finance
    (4, 2, 'member'),  -- David in sales
    (5, 1, 'member'),  -- Eve in engineering
    (5, 5, 'member');  -- Eve in hr
