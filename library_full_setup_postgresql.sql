DROP TABLE IF EXISTS loans CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS users CASCADE;


-- Tabla: users
CREATE TABLE users (
    user_id     INTEGER PRIMARY KEY,
    full_name   VARCHAR(100),
    email       VARCHAR(100),
    membership_date DATE
);

INSERT INTO users VALUES (1, 'Ana Torres', 'ana.torres@example.com', TO_TIMESTAMP('2021-01-10','YYYY-MM-DD')::DATE);
INSERT INTO users VALUES (2, 'Luis Pérez', 'luis.perez@example.com', TO_TIMESTAMP('2020-06-05','YYYY-MM-DD')::DATE);
INSERT INTO users VALUES (3, 'Marta Díaz', 'marta.diaz@example.com', TO_TIMESTAMP('2022-03-15','YYYY-MM-DD')::DATE);
INSERT INTO users VALUES (4, 'Carlos Ruiz', 'carlos.ruiz@example.com', TO_TIMESTAMP('2023-02-20','YYYY-MM-DD')::DATE);
INSERT INTO users VALUES (5, 'Laura Sánchez', 'laura.sanchez@example.com', TO_TIMESTAMP('2021-09-12','YYYY-MM-DD')::DATE);

-- Tabla: books
CREATE TABLE books (
    book_id     INTEGER PRIMARY KEY,
    title       VARCHAR(150),
    author      VARCHAR(100),
    published_year INTEGER,
    genre       VARCHAR(50)
);

INSERT INTO books VALUES (1, 'Cien Años de Soledad', 'Gabriel García Márquez', 1967, 'Novela');
INSERT INTO books VALUES (2, '1984', 'George Orwell', 1949, 'Distopía');
INSERT INTO books VALUES (3, 'El Principito', 'Antoine de Saint-Exupéry', 1943, 'Fábula');
INSERT INTO books VALUES (4, 'Don Quijote de la Mancha', 'Miguel de Cervantes', 1605, 'Clásico');
INSERT INTO books VALUES (5, 'Rayuela', 'Julio Cortázar', 1963, 'Novela');

-- Tabla: loans
CREATE TABLE loans (
    loan_id     INTEGER PRIMARY KEY,
    user_id     INTEGER,
    book_id     INTEGER,
    loan_date   DATE,
    return_date DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
);

INSERT INTO loans VALUES (1, 1, 2, TO_TIMESTAMP('2024-03-01','YYYY-MM-DD')::DATE, TO_TIMESTAMP('2024-03-15','YYYY-MM-DD')::DATE);
INSERT INTO loans VALUES (2, 2, 3, TO_TIMESTAMP('2024-03-05','YYYY-MM-DD')::DATE, TO_TIMESTAMP('2024-03-20','YYYY-MM-DD')::DATE);
INSERT INTO loans VALUES (3, 3, 1, TO_TIMESTAMP('2024-03-10','YYYY-MM-DD')::DATE, TO_TIMESTAMP('2024-03-25','YYYY-MM-DD')::DATE);
INSERT INTO loans VALUES (4, 4, 5, TO_TIMESTAMP('2024-03-12','YYYY-MM-DD')::DATE, NULL);
INSERT INTO loans VALUES (5, 5, 4, TO_TIMESTAMP('2024-03-15','YYYY-MM-DD')::DATE, NULL);
