# advanced-customer-endpoint — RESTful Microservice in Xbase++

A production-ready REST microservice that manages customer data, demonstrating
interceptors, JWT authentication, and the WAContainer pattern for thread-safe
DBF access.

The service exposes a customer API on port **9000**:

| Method | Route | Auth | Purpose |
|---|---|---|---|
| POST | `/auth/login` | public | exchange credentials for a JWT token |
| GET | `/customer/all` | Bearer | list all customers |
| GET | `/customer/:id` | Bearer | one customer by ID |
| GET | `/customer/search/:name` | Bearer | search customers by name |
| POST | `/customer` | Bearer | add a new customer |
| PUT | `/customer/:id` | Bearer | update an existing customer |
| DELETE | `/customer/:id` | Bearer | delete a customer |

Demo credentials: **`alice` / `secret`**.

---

## Checkout

```bat
git clone https://github.com/alaska-software/advanced-customer-endpoint.git 
cd advanced-customer-endpoint
```

## Build and Run

**1. Install assets and build**

```bat
xppam PROJECT -install
pbuild project.xpj
```


**2. Create the database**

```bat
cd run
create-data.exe
```

**3. Start the service**

```bat
advcustsvc.exe -exe
```

The service starts on `http://localhost:9000`.

**Quick smoke-test:**

Obtain a token:
```bat
curl -s -X POST http://localhost:9000/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"user\":\"alice\",\"password\":\"secret\"}"
```

Call a protected route (paste the token from the response above)
```bat
curl -s http://localhost:9000/customer/all ^
  -H "Authorization: Bearer <token>"
```

---

## Run the tests

Tier-1 tests (no service required):

```bat
cd unit-test
runner.exe /v /g:AuthServiceTestGroup
runner.exe /v /g:CustomerDataMgrTests
```

Tier-2 integration tests (service must be running):

```bat
runner.exe /v /g:AuthLoginTestGroup
runner.exe /v /g:RestCustTestGroup
```

---

## Learn more

For a full explanation of every pattern used in this project — routes, interceptors,
JWT authentication, WAContainer, and the testing strategy — read the
**[Advanced Customer Endpoint Guide — Alaska Software Documentation](https://guide.alaska-software.com/restful-advanced-customer-endpoint.html)**.
