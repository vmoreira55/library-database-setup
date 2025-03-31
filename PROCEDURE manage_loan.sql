/*
Bad Practices Implemented:

Improper Use of Data Types:

TEXT data types are used for identifiers (p_user_id, p_book_id) and dates (p_loan_date, p_return_date), which is inappropriate and can lead to implicit conversions and errors.

Lack of Transactions:

BEGIN, COMMIT, and ROLLBACK are not used, which can leave the database in an inconsistent state if an error occurs during execution.

Absence of Validations:

The existence of the user or the book is not verified before proceeding with operations.

It is not checked whether the user already has the book before registering a new loan.

It is not validated whether an active loan exists before registering a return.

Poor Error Handling:

EXCEPTION blocks are not implemented to capture and handle specific errors, which can cause the procedure to fail abruptly without providing information. Useful.

Generic Messages:

Notification messages (RAISE NOTICE) are vague and do not include specific details about the operations performed, making tracking and auditing difficult.

Unrestricted Updates and Deletes:

INSERT and UPDATE operations are performed without proper conditions, which can lead to incorrect modifications or insertions into the database.

Lack of Transaction Control:

The commit (COMMIT) or rollback (ROLLBACK) of transactions is not controlled, which can result in inconsistent data in the event of errors.

This example illustrates how the omission of best practices and the implementation of poor practices can lead to an inefficient, error-prone, and difficult-to-maintain stored procedure. It is essential to follow best practices in the design and development of stored procedures to ensure the integrity, security, and optimal performance of the database.
*/

-- Creating the stored procedure manage_loan_with_bad_practices
CREATE OR REPLACE PROCEDURE manage_loan_with_bad_practices(
IN p_action TEXT, -- Use of a generic and larger data type than necessary
IN p_user_id TEXT, -- Use of an inappropriate data type for identifiers
IN p_book_id TEXT, -- Use of an inappropriate data type for identifiers
IN p_loan_date TEXT, -- Use of an inappropriate data type for dates
IN p_return_date TEXT -- Use of an inappropriate data type for dates
)
LANGUAGE plpgsql
AS $$
DECLARE
v_existing_loans INTEGER;
v_book_title TEXT;
v_user_name TEXT;
v_due_date TEXT;
v_days_late TEXT;
v_fine TEXT;
v_loan_id TEXT;
BEGIN
-- No explicit transaction is initiated

-- The existence of the book or the user is not verified
-- Possible errors in queries are not handled

-- Loan action
IF p_action = 'loan' THEN
-- No verification of whether the user already has the book on loan
-- Direct insert without validations
INSERT INTO loans (user_id, book_id, loan_date)
VALUES (p_user_id, p_book_id, p_loan_date);

-- Generic message without specific details
RAISE NOTICE 'Loan recorded.';

-- Return action
ELSIF p_action = 'return' THEN
-- No verification of whether an active loan exists
-- Direct update without validations
UPDATE loans
SET return_date = p_return_date
WHERE user_id = p_user_id AND book_id = p_book_id;

-- Generic message without specific details
RAISE NOTICE 'Return recorded.';

ELSE
-- Handling of invalid action without specific details
RAISE EXCEPTION 'Invalid action.';
END IF;

-- Transaction commit or rollback is not handled
-- General exception is not handled
END;
$$;

/*
Procedure Logic:

Initial Checks: Ensures that both the book and the user exist in their respective tables.

Book Loan:

Verifies that the user does not already have the book borrowed and returned.

Inserts a new record in the loans table with the loan information.

Book Return:

Finds the most recent active loan for the specified user and book.

Calculates whether the return is late and determines the corresponding penalty.

Updates the loan record with the return date.

Transaction and Error Handling:

Uses a transaction to ensure atomicity of operations.

Implements an EXCEPTION block to capture and handle any errors, performing a ROLLBACK in case of failure.
*/

-- Create the manage_loan stored procedure
CREATE OR REPLACE PROCEDURE manage_loan(
IN p_action VARCHAR(10), -- Action to perform: 'loan' or 'return'
IN p_user_id INTEGER, -- User ID
IN p_book_id INTEGER, -- Book ID
IN p_loan_date DATE DEFAULT NULL, -- Loan date (optional)
IN p_return_date DATE DEFAULT NULL -- Return date (optional)
)
LANGUAGE plpgsql
AS $$
DECLARE
v_existing_loans INTEGER;
v_book_title VARCHAR(150);
v_user_name VARCHAR(100);
v_due_date DATE;
v_days_late INTEGER;
v_fine NUMERIC;
v_loan_id INTEGER; BEGIN
-- Start a transaction
BEGIN
-- Get the book title and username for records
SELECT title INTO v_book_title FROM books WHERE book_id = p_book_id;
SELECT full_name INTO v_user_name FROM users WHERE user_id = p_user_id;

-- Check if the book and username exist
IF v_book_title IS NULL THEN
RAISE EXCEPTION 'Book with ID % does not exist.', p_book_id;
END IF;

IF v_user_name IS NULL THEN
RAISE EXCEPTION 'User with ID % does not exist.', p_user_id;
END IF;

-- Loan Action
IF p_action = 'loan' THEN
-- Check if the user already has the book on loan and not returned it
SELECT COUNT(*) INTO v_existing_loans
FROM loans
WHERE user_id = p_user_id AND book_id = p_book_id AND return_date IS NULL;

IF v_existing_loans > 0 THEN
RAISE EXCEPTION 'User % already has the book "%" on loan and not returned it.', v_user_name, v_book_title;
END IF;

-- Register the loan
INSERT INTO loans (user_id, book_id, loan_date)
VALUES (p_user_id, p_book_id, COALESCE(p_loan_date, CURRENT_DATE));

RAISE NOTICE 'Loan registered: User "%" has borrowed the book "%".', v_user_name, v_book_title;

-- Return Action
ELSIF p_action = 'return' THEN
-- Get the active loan ID
SELECT loan_id, loan_date INTO v_loan_id, v_due_date
FROM loans
WHERE user_id = p_user_id AND book_id = p_book_id AND return_date IS NULL
ORDER BY loan_date DESC
LIMIT 1;

IF v_loan_id IS NULL THEN
RAISE EXCEPTION 'No active loan found for user % and book "%".', v_user_name, v_book_title;
END IF;

-- Calculate days late and penalty if applicable
v_due_date := v_due_date + INTERVAL '14 days'; -- Assuming a 14-day loan period
v_days_late := GREATEST(0, CURRENT_DATE - v_due_date);
v_fine := v_days_late * 0.50; -- Assuming a penalty of 0.50 per day late

-- Update the loan record with the return date
UPDATE loans
SET return_date = COALESCE(p_return_date, CURRENT_DATE)
WHERE loan_id = v_loan_id;

IF v_days_late > 0 THEN
RAISE NOTICE 'Return recorded % days late. Penalty applied: $%.', v_days_late, v_fine;
ELSE
RAISE NOTICE 'Return recorded on time. No penalty applied.';
END IF;

ELSE
RAISE EXCEPTION 'Invalid action. Use "loan" or "return."';
END IF;

-- Commit the transaction
COMMIT;
EXCEPTION
WHEN OTHERS THEN
-- Roll back the transaction on error
ROLLBACK;
RAISE;
END;
END;
$$;