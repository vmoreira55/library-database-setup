# 📊 Library Database System

This project contains the necessary SQL scripts for the complete creation and setup of a **library-oriented database system**. It includes both the schema definitions, initial data inserts, and SQL queries for practice and testing.

---

## 📁 Contents

- `library_postgresql_ready.sql`: Full setup script including table creation, relationships, and test data inserts for demonstration purposes.
- `library_queries_postgresql.sql`: SQL queries for testing and interacting with the library database.

---

## 🛠️ Technologies Used

- Standard SQL
- PostgreSQL
- pgAdmin

---

## 🚀 How to Use

1. Open pgAdmin or your preferred PostgreSQL client.
2. Run the `library_postgresql_ready.sql` file to create the schema and load sample data.
3. Run the `library_queries_postgresql.sql` file to test queries and explore the system.

---

## 🧠 Key Features

- Relational design with foreign key constraints
- Referential integrity ensured
- Realistic test data to simulate library operations
- Includes queries to analyze user behavior, book loans, and activity logs
- The manage_loan stored procedure in PostgreSQL manages book borrowing and returning operations in a library, ensuring data integrity and applying essential validations. It verifies the existence of patrons and books, controls that a patron does not have multiple active borrowings of the same book, and when processing returns, calculates the corresponding late fees and fines. It also implements error handling to maintain database consistency.
---

## 🧑‍💻 Author

**Virlis Moreira**  
https://www.upwork.com/freelancers/~01b97b4c669aea29e3?mp_source=share  
http://www.linkedin.com/in/virlis-moreira-vivas

---

## 📄 License

This project is available under the MIT License.
