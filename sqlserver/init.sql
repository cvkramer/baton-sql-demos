-- SQL Server init script for baton-sql demo
-- Run this after the container starts

-- Create demo database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'demo')
BEGIN
    CREATE DATABASE demo;
END
GO

USE demo;
GO

-- Users table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'users')
BEGIN
    CREATE TABLE users (
        id INT IDENTITY(1,1) PRIMARY KEY,
        email NVARCHAR(255) UNIQUE NOT NULL,
        first_name NVARCHAR(100) NOT NULL,
        last_name NVARCHAR(100) NOT NULL,
        status NVARCHAR(20) DEFAULT 'active',
        created_at DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- Groups table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'groups')
BEGIN
    CREATE TABLE groups (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(100) UNIQUE NOT NULL,
        description NVARCHAR(MAX),
        created_at DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- Group memberships (many-to-many)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'group_memberships')
BEGIN
    CREATE TABLE group_memberships (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL,
        group_id INT NOT NULL,
        role NVARCHAR(50) DEFAULT 'member',
        created_at DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_memberships_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        CONSTRAINT FK_memberships_group FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
        CONSTRAINT UQ_user_group UNIQUE (user_id, group_id)
    );
END
GO

-- Sample data: Users
INSERT INTO users (email, first_name, last_name, status) VALUES
    ('alice@example.com', 'Alice', 'Anderson', 'active'),
    ('bob@example.com', 'Bob', 'Baker', 'active'),
    ('carol@example.com', 'Carol', 'Chen', 'active'),
    ('david@example.com', 'David', 'Davis', 'inactive'),
    ('eve@example.com', 'Eve', 'Edwards', 'active'),
    ('frank@example.com', 'Frank', 'Fisher', 'suspended');
GO

-- Sample data: Groups
INSERT INTO groups (name, description) VALUES
    ('engineering', 'Engineering team'),
    ('sales', 'Sales department'),
    ('admin', 'System administrators'),
    ('finance', 'Finance and accounting'),
    ('hr', 'Human resources');
GO

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
GO
