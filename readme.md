# Advanced Customer Endpoint - RESTful Microservice

A production-ready RESTful microservice built with Alaska Xbase++ for managing
customer data. Features a complete implementation of REST patterns including
interceptors, caching, authentication, and efficient database operations using
the WAContainer pattern.

## Overview

This microservice demonstrates enterprise-grade patterns for building stateless
REST APIs with:

- **RESTful API** for full CRUD operations on customer data
- **Interceptor chain** for cross-cutting concerns (authentication, logging,
  caching)
- **WAContainer pattern** for efficient multi-threaded database access
- **DBF/CDX database** with indexed customer records
- **Service deployment** supporting both console and Windows service modes

## Architecture

### Service Layer (`service/`)

- **adv-cust-svc-main.prg** - Main entry point with service control commands (
  install/uninstall/start/stop)
- **adv-cust-svc-microservice.prg** - Microservice lifecycle implementation (
  AdvCustSvc class)
- **advanced-customer-handler.prg** - REST handler with route mappings and HTTP
  method implementations
- **auth-interceptor.prg** - API key authentication interceptor (validates
  Authorization header)
- **cache-interceptor.prg** - Result caching interceptor for GET operations
- **logging-interceptor.prg** - Request/response logging with execution timing
- **advcustsvc.exe.config** - Service configuration (endpoint, port, health
  monitoring, recovery manager)

### Business Logic Layer (`business-logic/`)

- **customer-data-manager.prg** - CRUD operations for customer data (
  CustomerDataMgr class)
- **wa-container.prg** - Stateless workarea container for efficient
  multi-threaded database access
- **auth-service.prg** - Authentication service with API key validation

### Data Layer

- **customer-schema.prg** - DBF table structure definition and index creation
- **main.prg** - Database initialization utility (creates customer.dbf and
  indexes)

### Configuration

- **project.xpj** - Build configuration defining three targets:
    - `customer-core.dll` - Business logic DLL
    - `advcustsvc.exe` - REST microservice executable
    - `create-data.exe` - Database creation utility

## API Endpoints

All endpoints are served on port **9000** (configurable in
advcustsvc.exe.config).

### Authentication

All requests require an `Authorization` header:

```
Authorization: Bearer demo-api-key-12345
```

### Routes

| Method | Endpoint                 | Handler Method           | Description               |
|--------|--------------------------|--------------------------|---------------------------|
| GET    | `/customer/all`          | getAll()                 | Retrieve all customers    |
| GET    | `/customer/:id`          | getById(nId)             | Retrieve customer by ID   |
| GET    | `/customer/search/:name` | getByName(cName)         | Search customers by name  |
| PUT    | `/customer/:id`          | saveById(nId, oCustomer) | Create or update customer |
| DELETE | `/customer/:id`          | deleteById(nId)          | Delete customer by ID     |

All responses use the "envelope" format.

## Customer Data Schema

The customer table includes the following fields:

| Field     | Type | Size | Description               |
|-----------|------|------|---------------------------|
| cust_id   | C    | 8    | Customer ID (primary key) |
| firstname | C    | 50   | First name                |
| lastname  | C    | 50   | Last name                 |
| email     | C    | 100  | Email address             |
| phone     | C    | 20   | Phone number              |
| street    | C    | 100  | Street address            |
| city      | C    | 50   | City                      |
| state     | C    | 50   | State/Province            |
| zipcode   | C    | 10   | ZIP/Postal code           |
| country   | C    | 50   | Country                   |
| active    | L    | 1    | Active status flag        |
| created   | D    | 8    | Creation date             |
| modified  | D    | 8    | Last modification date    |
| notes     | M    | 10   | Memo field for notes      |

### Indexes

- **cust_id** - Primary key index
- **name** - Full name index (lastname + firstname)
- **email** - Email lookup index
- **city** - City-based queries
- **active** - Active status filter

## Building the Project

Build all targets:

```
xbp project.xpj
```

This generates:

- `business-logic\customer-core.dll`
- `service\advcustsvc.exe`
- `create-data.exe`

## Setup and Deployment

### 1. Create the Database

```
create-data.exe
```

This creates `customer.dbf` with indexes in the current directory.

### 2. Run as Console Application

```
advcustsvc.exe -exe
```

### 3. Install and Run as Windows Service

```
advcustsvc.exe service -install
advcustsvc.exe service -start
```

### 4. Service Management Commands

```
advcustsvc.exe service -status          # Check service status
advcustsvc.exe service -stop            # Stop service
advcustsvc.exe service -uninstall       # Remove service
advcustsvc.exe service -user:DOMAIN\USER -password:PWD -install  # Install with credentials
```

### 5. Recovery Manager Commands

```
advcustsvc.exe rm -reset                # Reset recovery state
advcustsvc.exe rm -recover              # Run recovery only
```

## Key Features

### Interceptor Chain

Interceptors execute in registration order (see advanced-customer-handler.prg:
36-47):

1. **LoggingInterceptor** - Logs all requests/responses with timing
2. **AuthInterceptor** - Validates API keys for all methods
3. **CacheInterceptor** - Caches results for read operations (getAll, getById,
   getByName)

### WAContainer Pattern

The WAContainer pattern (wa-container.prg) provides:

- **Performance optimization** via DbRelease()/DbRequest() instead of repeated
  USE/CLOSE
- **Thread-safe** workarea pooling in the zero workspace
- **Stateless operations** perfect for multi-threaded service workloads
- **Automatic workarea stack management** preserving caller context

### Recovery Manager

Configured in advcustsvc.exe.config:

- **ResetTimeframe**: 10 minutes
- **RecoverThreshold**: 3 restart attempts before recovery mode

### Health Monitoring

- **CPU limit watchdog**: 50% threshold
- **Memory limit watchdog**: 100MB threshold

## Dependencies

The service depends on Alaska Xbase++ assets:

- `microservice-core` - Base microservice framework
- `configuration-manager` - XML configuration handling
- `console-helper` - Command-line argument processing
- `rest-helper` - REST handler and interceptor framework

## Configuration

Edit `service/advcustsvc.exe.config` to customize:

- Service name
- Endpoint IP and port
- Health monitoring thresholds
- Recovery manager settings
- Handler class registration

## Development Notes

### Adding New Interceptors

1. Create new interceptor class extending `RestInterceptor`
2. Implement `before()`, `after()`, and/or `onError()` methods
3. Register in `CustomerHandler:onRegister()` method
4. Add to project.xpj and rebuild

### Modifying Customer Schema

1. Update `GetCustomerStructure()` in customer-schema.prg
2. Update `CreateCustomerIndexes()` as needed
3. Modify `CustomerWAContainer:toWorkarea()` and `fromWorkarea()` in
   customer-data-manager.prg
4. Rebuild and recreate the database

## Security Note

**The authentication implementation uses a hard-coded API key for demonstration
purposes.** In production:

- Implement proper JWT or OAuth2 token validation
- Use secure key storage (environment variables, key vaults)
- Add HTTPS/TLS encryption
- Implement rate limiting and request throttling
- Add audit logging for security events
