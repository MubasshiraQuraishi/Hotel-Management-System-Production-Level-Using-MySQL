/*
Query Optimization (Execution Plan, Indexing Strategy)

Triggers for Audits

User Management (GRANT/REVOKE, Roles)

ETL Simulation — build staging + load logic

Schema Design — Normalization/De-normalization

Error Handling in Stored Procedures

Security & Compliance Use Cases*/

CREATE DATABASE hotel;
USE hotel;

CREATE TABLE Guests (
					  guest_id INT PRIMARY KEY,
                      first_name VARCHAR(50),
                      last_name VARCHAR(50),
                      email VARCHAR(30) UNIQUE,
                      phone VARCHAR(15),
                      id_proof_type VARCHAR(20),
                      id_proof_number VARCHAR(30),
                      nationality VARCHAR(30),
                      check_in_status BOOLEAN DEFAULT FALSE);
                      
CREATE TABLE Rooms (
					room_id INT PRIMARY KEY,
                    room_number VARCHAR(10),
                    room_type VARCHAR(10),
                    price_per_night DECIMAL(10,2),
                    floor_number INT,
                    is_available BOOLEAN DEFAULT TRUE);
	
CREATE TABLE Bookings (
						booking_id  INT PRIMARY KEY,
                        guest_id INT,
                        room_id INT,
                        check_in_date DATE,
                        check_out_date DATE,
                        booking_status VARCHAR(20),
                        FOREIGN KEY (guest_id) REFERENCES Guests(guest_id),
                        FOREIGN KEY (room_id) REFERENCES Rooms(room_id)
                        );
                        
CREATE TABLE Payments (	
						payment_id INT PRIMARY KEY,
                        booking_id INT,
                        payment_date DATE,
                        payment_mode VARCHAR(20),
                        total_amount DECIMAL(10, 2),
                        paid_amount DECIMAL(10, 2),
						balance_due DECIMAL(10, 2),
                        payment_status VARCHAR(20),
                        FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id));
                        
INSERT INTO Guests (guest_id, first_name, last_name, email, phone, id_proof_type, id_proof_number, nationality, check_in_status) VALUES
(1, 'Aisha', 'Khan', 'aisha.khan@gmail.com', '9876543210', 'Aadhar', 'A123456789', 'Indian', FALSE),
(2, 'Raj', 'Mehta', 'raj.mehta@yahoo.com', '9123456789', 'Passport', 'P98123456', 'Indian', TRUE),
(3, 'Sara', 'Dsouza', 'sara.d@gmail.com', '9988776655', 'Aadhar', 'A456987321', 'Indian', TRUE),
(4, 'Omar', 'Sheikh', 'osheikh@hotmail.com', '9654321890', 'Voter ID', 'V78654321', 'Indian', FALSE),
(5, 'Nina', 'Patel', 'nina.patel@gmail.com', '9871234560', 'Aadhar', 'A654321789', 'Indian', TRUE),
(6, 'Dev', 'Kapoor', 'devk@outlook.com', '9123987654', 'Driving License', 'DL9988776', 'Indian', FALSE),
(7, 'Fatima', 'Ansari', 'fatima.ansari@mail.com', '9876012345', 'Passport', 'P12345678', 'Indian', FALSE),
(8, 'Jacob', 'Diaz', 'jacobdiaz@gmail.com', '9001122334', 'Aadhar', 'A112233445', 'Indian', TRUE);

INSERT INTO Rooms (room_id, room_number, room_type, price_per_night, floor_number, is_available) VALUES
(101, 'A101', 'Deluxe', 3500.00, 1, FALSE),
(102, 'A102', 'Standard', 2500.00, 1, TRUE),
(103, 'B201', 'Suite', 5500.00, 2, FALSE),
(104, 'B202', 'Standard', 2400.00, 2, TRUE),
(105, 'C301', 'Deluxe', 3700.00, 3, TRUE),
(106, 'C302', 'Suite', 6000.00, 3, TRUE),
(107, 'D401', 'Standard', 2200.00, 4, TRUE),
(108, 'D402', 'Deluxe', 3600.00, 4, FALSE);

INSERT INTO Bookings (booking_id, guest_id, room_id, check_in_date, check_out_date, booking_status) VALUES
(1, 2, 101, '2024-06-15', '2024-06-18', 'Checked-Out'),
(2, 3, 103, '2024-06-18', '2024-06-22', 'Checked-In'),
(3, 5, 108, '2024-06-20', '2024-06-23', 'Cancelled'),
(4, 8, 101, '2024-06-23', '2024-06-26', 'Confirmed'),
(5, 1, 104, '2024-06-21', '2024-06-23', 'Confirmed'),
(6, 6, 105, '2024-06-25', '2024-06-28', 'Confirmed');

INSERT INTO Payments (payment_id, booking_id, payment_date, payment_mode, total_amount, paid_amount, balance_due, payment_status) VALUES
(1, 1, '2024-06-15', 'Card', 10500.00, 10500.00, 0.00, 'Paid'),
(2, 2, '2024-06-18', 'Cash', 22000.00, 15000.00, 7000.00, 'Partial'),
(3, 3, NULL, NULL, 10800.00, 0.00, 10800.00, 'Pending'),
(4, 4, NULL, NULL, 10800.00, 0.00, 10800.00, 'Pending'),
(5, 5, '2024-06-21', 'UPI', 4800.00, 4800.00, 0.00, 'Paid'),
(6, 6, '2024-06-25', 'Card', 11100.00, 11100.00, 0.00, 'Paid');

CREATE INDEX idx_b_guest_id ON Bookings(guest_id);
CREATE INDEX idx_b_room_id ON Bookings(room_id);
CREATE INDEX idx_p_booking_id ON Payments(booking_id);
DELIMITER $$
CREATE TRIGGER prevent_invalid_bookings
BEFORE INSERT ON Bookings
FOR EACH ROW
BEGIN 
	DECLARE v_room_id INT;
	DECLARE v_room_availability BOOLEAN;
    
    SELECT room_id
    INTO v_room_id
    FROM rooms
    WHERE room_id = NEW.room_id;
    
	SELECT is_available
    INTO v_room_availability 
    FROM rooms
    WHERE room_id = NEW.room_id;
    
    IF v_room_id IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Room ID';
    ELSEIF v_room_availability = FALSE THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Room already occupied';
	END IF;
END $$

DELIMITER $$
CREATE TRIGGER new_booking
AFTER INSERT ON Bookings
FOR EACH ROW
BEGIN
	IF NEW.booking_status  = 'Confirmed' THEN
		UPDATE Rooms
		SET is_available = FALSE
		WHERE room_id = NEW.room_id;
    END IF;
END $$

DROP PROCEDURE IF EXISTS check_in_guest;
DELIMITER $$
CREATE PROCEDURE check_in_guest(p_booking_id INT)
BEGIN
	DECLARE Booking_exists INT DEFAULT 0;
	DECLARE v_guest_id INT;
    
		SELECT guest_id INTO v_guest_id FROM Bookings WHERE booking_id = p_booking_id;
	
        SET Booking_exists = 1;
		IF Booking_exists = 1 THEN
			UPDATE Bookings
			SET booking_status = 'Checked-In'
			WHERE booking_id = p_booking_id;
			
			UPDATE Guests
			SET check_in_status = TRUE
			WHERE guest_id = v_guest_id;
			
			SELECT 'Guest Check-in Confirmed' AS message;
		END IF;
END $$

DROP VIEW IF EXISTS booking_payment_summary;
CREATE VIEW booking_payment_summary AS 
SELECT CONCAT(first_name, " ", last_name) AS full_name, room_number, total_amount, paid_amount, balance_due, payment_status
FROM Bookings b
JOIN Guests g ON b.guest_id = g.guest_id
JOIN Rooms r ON b.room_id = r.room_id
JOIN payments p ON b.booking_id = p.booking_id;

SELECT * FROM booking_payment_summary;

DELIMITER $$
CREATE TRIGGER stop_overlap_bookings
BEFORE INSERT ON Bookings
FOR EACH ROW
BEGIN
	DECLARE v_already_booked INT DEFAULT 0;
    
	SELECT COUNT(*) INTO v_already_booked 
    FROM Bookings 
    WHERE room_id = NEW.room_id AND (NEW.check_in_date < check_out_date AND NEW.check_out_date > check_in_date);
    
    IF v_already_booked > 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Room Already Booked on the date';
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE cancellation_workflow(p_booking_id INT)
BEGIN
	DECLARE v_room_id INT;
    DECLARE booking_found BOOLEAN DEFAULT TRUE;
    
	DECLARE CONTINUE HANDLER FOR NOT FOUND
	SET booking_found = FALSE;
    
	SELECT room_id INTO v_room_id FROM Bookings WHERE booking_id = p_booking_id AND booking_status = 'Confirmed' LIMIT 1;
    IF booking_found THEN
		UPDATE Bookings
		SET booking_status = 'Cancelled'
		WHERE booking_id = p_booking_id;
		
		UPDATE Rooms
		SET is_available = TRUE
		WHERE room_id = v_room_id;
      
        SELECT 'Booking Cancelled' AS message;
    ELSE
        SELECT CONCAT('Booking ID ', p_booking_id, ' not found') AS message;
    END IF;

END $$

CREATE TABLE late_check_outs (
								late_check_out_id INT PRIMARY KEY AUTO_INCREMENT,
								booking_id INT,
                                guest_id INT,
                                room_id INT,
                                payment_id INT,
                                actual_check_out_date DATE,
                                late_check_out_date DATE,
                                actual_payment DECIMAL(10,2),
                                late_fees DECIMAL(10,2),
                                Total_payment DECIMAL(10,2),
								FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id),
                                FOREIGN KEY (guest_id) REFERENCES Guests(guest_id),
								FOREIGN KEY (room_id) REFERENCES Rooms(room_id),
                                FOREIGN KEY (payment_id) REFERENCES Payments(payment_id));

DROP PROCEDURE IF EXISTS late_check_out;
DELIMITER $$
CREATE PROCEDURE late_check_out (p_booking_id INT)
BEGIN 
	DECLARE v_guest_id INT;
    DECLARE v_room_id INT;
    DECLARE v_payment_id INT;
    DECLARE v_check_out_date DATE;
    DECLARE v_total_payment DECIMAL(10,2);
    
	SELECT guest_id, room_id, payment_id, check_out_date, total_amount
    INTO v_guest_id, v_room_id, v_payment_id, v_check_out_date, v_total_payment
    FROM bookings b
    JOIN payments p ON b.booking_id = p.booking_id
    WHERE b.booking_id = p_booking_id;
    
    IF CURRENT_DATE() > v_check_out_date THEN
		INSERT INTO late_check_outs (booking_id, guest_id, room_id, payment_id, actual_check_out_date, late_check_out_date, actual_payment, late_fees, Total_payment)
		VALUES (p_booking_id, v_guest_id, v_room_id, v_payment_id, v_check_out_date, CURRENT_DATE(), v_total_payment, DATEDIFF(CURRENT_DATE(), v_check_out_date) * 0.15, v_total_payment * 0.15 * (DATEDIFF(CURRENT_DATE(), v_check_out_date)));
	
    ELSE
		SELECT 'No late fee – guest checked out on time' AS message;
	END IF; 
END $$

CALL late_check_out(6);

SELECT * FROM late_check_outs;

ALTER TABLE Rooms
ADD room_maintenance VARCHAR(20);

DELIMITER $$
CREATE TRIGGER is_maintained_check
BEFORE INSERT ON Rooms
FOR EACH ROW
BEGIN
	IF NEW.room_maintenance IN ('Maintenance', 'cleaning') THEN
		UPDATE Rooms
        SET NEW.is_available = False;
	ELSE
		UPDATE Rooms
        SET NEW.is_available = True;
	END IF;
END $$

                        
DELIMITER $$
CREATE PROCEDURE pymt_mismatch_guard(p_payment_id INT)
BEGIN
		DECLARE v_paid_amount DECIMAL(10,2);
        DECLARE v_total_amount DECIMAL(10,2);
        
        SELECT paid_amount, total_amount 
        INTO v_paid_amount, v_total_amount
        FROM Payments;
        
		IF v_paid_amount > v_total_amount AND payment_id = p_payment_id THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Paid amount is greater than Total amount';
            
		ELSEIF v_paid_amount < v_total_amount AND payment_id = p_payment_id THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Paid amount is less than Total amount';
		ELSE 
			SELECT 'Paid amount is equal to total amount';
        
        END IF;
        
END $$

DELIMITER $$
CREATE PROCEDURE Monthly_revenue_report(p_month INT)
BEGIN 
	DECLARE v_room_id INT;
	SELECT COUNT(room_id) 
    INTO v_room_id 
    FROM rooms;

	IF p_month BETWEEN 1 AND 12 THEN 
		SELECT SUM(total_amount) AS total_revenue, COUNT(b.booking_id) AS total_bookings, ROUND((COUNT(b.room_id) / v_room_id *100),2) AS occupancy_rate
		FROM bookings b
		JOIN payments p ON b.booking_id = p.booking_id
		WHERE MONTH(b.check_in_date) = p_month;
	ELSE 
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Enter Valid Month number between 1 - 12';
	END IF;
END $$
DELIMITER $$
CREATE PROCEDURE guest_report(p_guest_id INT)
BEGIN 
	SELECT first_name, last_name, b.booking_id, check_in_date, check_out_date, booking_status, total_amount, paid_amount, balance_due
    FROM guests g
    JOIN bookings b ON b.guest_id = g.guest_id
    JOIN payments p ON b.booking_id = p.booking_id
    WHERE g.guest_id = p_guest_id;
END $$

CREATE ROLE Receptionist;
GRANT SELECT, INSERT, UPDATE ON Hotel.Bookings TO Receptionist;
GRANT SELECT ON Hotel.Guests TO Receptionist;

CREATE ROLE accountant;
GRANT SELECT ON Hotel.Payments TO accountant;

CREATE ROLE Operations;
GRANT SELECT, INSERT, UPDATE ON Hotel.Payments TO Operations;
GRANT SELECT, INSERT, UPDATE ON Hotel.Rooms TO Operations;

CREATE ROLE manager;
GRANT ALL PRIVILEGES ON Hotel.* TO manager;
DELIMITER $$
CREATE PROCEDURE check_in_confirmed_guests()
BEGIN
	DECLARE done INT DEFAULT FALSE;
    DECLARE v_guest_id INT;
	DECLARE cur CURSOR FOR SELECT guest_id FROM Bookings WHERE booking_status = 'Confirmed';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN cur;
		read_loop : LOOP
        FETCH cur INTO v_guest_id;
		
		IF done THEN
			LEAVE read_loop;
        END IF;
        
        UPDATE Guests SET check_in_status = TRUE WHERE guest_id = v_guest_id;
        END LOOP;
	CLOSE cur;
END $$

CREATE TABLE duplicate_guest_entries (
										guest_id INT,
                                        first_name VARCHAR(50),
										last_name VARCHAR(50),
										email VARCHAR(30));
                                        

DELIMITER $$
CREATE PROCEDURE flag_duplicate_guests()
BEGIN
	DECLARE done INT DEFAULT FALSE;
    DECLARE v_guest_id INT;
	DECLARE v_email_id VARCHAR(100);
	DECLARE v_email_count INT;
	DECLARE v_first_name VARCHAR(100);
	DECLARE v_last_name VARCHAR(100);

    DECLARE cur CURSOR FOR 
		SELECT guest_id, email, first_name, last_name 
		FROM Guests 
		WHERE email IN (
			SELECT email FROM Guests GROUP BY email HAVING COUNT(*) > 1
		);

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    read_loop : LOOP
    FETCH cur INTO v_guest_id, v_email_id, v_email_count, v_first_name, v_last_name;
    IF done THEN 
		LEAVE read_loop;
	END IF;
	INSERT INTO duplicate_guest_entries (guest_id, first_name, last_name, email)
	VALUES(v_guest_id, v_first_name, v_last_name, v_email_id);
    END LOOP;
    CLOSE cur;
END $$						

DELIMITER $$
CREATE PROCEDURE sync_booking_room_status()
BEGIN
	DECLARE done INT DEFAULT FALSE;
    DECLARE v_room_id INT;
    DECLARE cur CURSOR FOR
		SELECT r.room_id 
        FROM bookings b
        JOIN rooms r 
        ON b.room_id = r.room_id
        WHERE booking_status = 'Checked-out' AND r.is_available = FALSE;
        
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
	OPEN cur;
		read_loop : LOOP
			FETCH cur INTO v_room_id;
		
		IF done THEN
			LEAVE read_loop;
		END IF;
		
			UPDATE Rooms SET is_available = TRUE WHERE room_id = v_room_id;
		
		END LOOP;
    CLOSE cur;
END $$

-- Manual Transactions

DELIMITER $$
CREATE PROCEDURE reassign_room(p_booking_id INT, p_new_room_id INT)
BEGIN
	DECLARE old_room_id INT;
    DECLARE v_new_room_available BOOLEAN;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		ROLLBACK;
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Transaction failed, Rolling back';
    END;
    DECLARE EXIT HANDLER FOR SQLWARNING
    BEGIN
		ROLLBACK;
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error encountered, Rolling back';
	END;
    
    START TRANSACTION;
		SELECT r.room_id INTO old_room_id
		FROM Rooms r
        JOIN Bookings b ON b.room_id = r.room_id
        WHERE b.booking_id = p_booking_id;
        
        SELECT is_available 
		INTO v_new_room_available 
		FROM Rooms 
		WHERE room_id = p_new_room_id
        LIMIT 1;

		IF v_new_room_available = FALSE THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'New room is already occupied. Operation cancelled.';
		END IF;
        
	
		UPDATE Bookings
		SET room_id = p_new_room_id
		WHERE booking_id = p_booking_id;
        
        UPDATE Rooms
		SET is_available = TRUE
		WHERE room_id = old_room_id;
        
        UPDATE Rooms
		SET is_available = FALSE
		WHERE room_id = p_new_room_id;
	COMMIT;

END $$

-- First way
DELIMITER $$
CREATE PROCEDURE assign_loyalty_tiers()
BEGIN
	 DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction failed, rolling back';
    END;

    DECLARE EXIT HANDLER FOR SQLWARNING
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'SQL warning encountered, rolling back';
    END;
    
    START TRANSACTION;
		UPDATE Guests g
        JOIN (
				SELECT guest_id, COUNT(*) AS stay_count
                FROM Bookings
                WHERE booking_status = 'Checked-out'
                GROUP BY guest_id
			) b ON g.guest_id = b.guest_id
            
		SET g.loyalty_tier = CASE
								WHEN b.stay_count BETWEEN 1 AND 3 THEN 'Bronze'
								WHEN b.stay_count BETWEEN 4 AND 6 THEN 'Silver'
								WHEN b.stay_count >= 7 THEN 'Gold'
							ELSE NULL
                            END;
	COMMIT;
END $$
-- Second way
DELIMITER $$
CREATE PROCEDURE assign_loyalty_tiers()
BEGIN
	DECLARE v_guest_id INT;
    DECLARE v_check_out INT;
    DECLARE done INT DEFAULT FALSE;
    DECLARE cur CURSOR FOR
		SELECT guest_id, COUNT(*)
        FROM Bookings
        WHERE booking_status = 'checked_out'
        GROUP BY guest_id;
        
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		ROLLBACK;
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Transaction failed, Rolling back';
    END;
    DECLARE EXIT HANDLER FOR SQLWARNING
    BEGIN
		ROLLBACK;
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error encountered, Rolling back';
	END;
    
    START TRANSACTION;
		OPEN cur;
			read_loop : LOOP
				FETCH cur INTO v_guest_id, v_check_out;
			
				IF done THEN
					LEAVE read_loop;
				END IF;
				
				IF v_check_out BETWEEN 1 AND 3 THEN
					UPDATE Guests SET loyalty_tier = 'Bronze' WHERE guest_id = v_guest_id;
				ELSEIF v_check_out BETWEEN 4 AND 6 THEN
					UPDATE Guests SET loyalty_tier = 'Silver' WHERE guest_id = v_guest_id;
				ELSEIF v_check_out >= 7 THEN
					UPDATE Guests SET loyalty_tier = 'Gold' WHERE guest_id = v_guest_id;
				ELSE
					UPDATE Guests SET loyalty_tier = NULL WHERE guest_id = v_guest_id;
				END IF;
            END LOOP;
		CLOSE cur;
	COMMIT;
END $$


ALTER TABLE Guests
ADD COLUMN guest_type VARCHAR(30);


DELIMITER $$
CREATE PROCEDURE guest_with_diff_rooms()
BEGIN
	DECLARE v_guest_id INT;
    DECLARE v_room_type INT;
    DECLARE done INT DEFAULT FALSE;
    DECLARE cur CURSOR FOR
		SELECT b.guest_id, COUNT(DISTINCT r.room_type)
        FROM Bookings b
        JOIN Rooms r
        ON b.room_id = r.room_id
        GROUP BY b.guest_id;
        
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		ROLLBACK;
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Transaction failed, Rolling back';
    END;
    DECLARE EXIT HANDLER FOR SQLWARNING
    BEGIN
		ROLLBACK;
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error encountered, Rolling back';
	END;
    
    START TRANSACTION;
		OPEN cur;
			read_loop : LOOP
				FETCH cur INTO v_guest_id, v_room_type;
			
				IF done THEN
					LEAVE read_loop;
				END IF;
				
				IF v_room_type < 3 THEN
					UPDATE Guests SET guest_type = 'Inflexible Guest' WHERE guest_id = v_guest_id;
				ELSE
					UPDATE Guests SET guest_type = 'Versatile Guest' WHERE guest_id = v_guest_id;
				END IF;
            END LOOP;
		CLOSE cur;
	COMMIT;
END $$

-- Dynamic SQL

DROP PROCEDURE IF EXISTS get_guest_bookings_dynamic;
DELIMITER $$
CREATE PROCEDURE get_guest_bookings_dynamic(
    IN p_column_name VARCHAR(50),
    IN p_value VARCHAR(100)
)
BEGIN
	 DECLARE v_sql TEXT;
    SET v_sql = ('SELECT g.guest_id,
						CONCAT(g.first_name, " ", g.last_name) AS full_name,
						b.booking_id,
						b.booking_status,
						r.room_number,
						b.check_in_date,
						b.check_out_date
						FROM Bookings b
						JOIN Guests g ON b.guest_id = g.guest_id
						JOIN Rooms r ON b.room_id = r.room_id
						WHERE ');
                        
	IF p_column_name = 'guest_id' THEN
    SET v_sql = CONCAT(v_sql, 'g.guest_id = "', p_value, '"');
    
    ELSEIF p_column_name = 'first_name' THEN
        SET v_sql = CONCAT(v_sql, 'g.first_name = "', p_value, '"');
        
    ELSEIF p_column_name = 'room_number' THEN
        SET v_sql = CONCAT(v_sql, 'r.room_number = "', p_value, '"');

    ELSEIF p_column_name = 'room_id' THEN
        SET v_sql = CONCAT(v_sql, 'b.room_id = "', p_value, '"');

    ELSEIF p_column_name = 'booking_status' THEN
        SET v_sql = CONCAT(v_sql, 'b.booking_status = "', p_value, '"');

    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Unsupported column name';
    END IF;
	
    SET @query = v_sql;
    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END $$