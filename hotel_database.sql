-- Διαγραφή υπαρχόντων πινάκων
DROP TABLE IF EXISTS Payment, BookingService, BookingGuest, Booking, Guest, Room, RoomType, Service, Staff, BookingServiceStaff;

-- Δημιουργία πινάκων
CREATE TABLE RoomType (
    room_type_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    price_per_night DECIMAL(10, 2) NOT NULL
);

CREATE TABLE Room (
    room_id INT PRIMARY KEY AUTO_INCREMENT,
    room_number VARCHAR(10) UNIQUE NOT NULL,
    room_type_id INT NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (room_type_id) REFERENCES RoomType(room_type_id)
);

CREATE TABLE Guest (
    guest_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20)
);

CREATE TABLE Booking (
    booking_id INT PRIMARY KEY AUTO_INCREMENT,
    room_id INT NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    total_cost DECIMAL(10,2),
    FOREIGN KEY (room_id) REFERENCES Room(room_id)
);

CREATE TABLE BookingGuest (
    booking_id INT,
    guest_id INT,
    PRIMARY KEY (booking_id, guest_id),
    FOREIGN KEY (booking_id) REFERENCES Booking(booking_id),
    FOREIGN KEY (guest_id) REFERENCES Guest(guest_id)
);

CREATE TABLE Service (
    service_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL
);

CREATE TABLE BookingService (
    booking_id INT,
    service_id INT,
    quantity INT DEFAULT 1,
    PRIMARY KEY (booking_id, service_id),
    FOREIGN KEY (booking_id) REFERENCES Booking(booking_id),
    FOREIGN KEY (service_id) REFERENCES Service(service_id)
);

CREATE TABLE Staff (
    staff_id INT PRIMARY KEY AUTO_INCREMENT,
    employee VARCHAR(50),
    role VARCHAR(50),
    is_available BOOLEAN DEFAULT TRUE
);

CREATE TABLE BookingServiceStaff (
    booking_id INT,
    service_id INT,
    staff_id INT NULL,
    PRIMARY KEY (booking_id, service_id),
    FOREIGN KEY (booking_id, service_id) REFERENCES BookingService(booking_id, service_id),
    FOREIGN KEY (staff_id) REFERENCES Staff(staff_id)
);

CREATE TABLE Payment (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    booking_id INT NOT NULL,
    amount DECIMAL(10,2),
    payment_date DATE,
    payment_method VARCHAR(50),
    FOREIGN KEY (booking_id) REFERENCES Booking(booking_id)
);

-- Εισαγωγη δεδομενων για δοκιμη

INSERT INTO RoomType (name, price_per_night) VALUES
('Single', 50.00),
('Double', 80.00),
('Suite', 150.00),
('Triple', 100.00);

INSERT INTO Room (room_number, room_type_id, is_available) VALUES
('101', 1, TRUE),
('102', 3, FALSE),
('201', 2, TRUE),
('202', 1, FALSE),
('301', 3, TRUE),
('401', 4, TRUE),
('402', 4, TRUE);

INSERT INTO Guest (first_name, last_name, email, phone) VALUES
('Nikos', 'Papadopoulos', 'nikos@yahoo.gr', '6911111111'),
('Maria', 'Ioannou', 'maria@gmail.com', '6922222222'), 
('Giorgos', 'Kokkinakis', 'giorgos@hotmail.com', '6933333333'); 

INSERT INTO Booking (room_id, check_in_date, check_out_date, total_cost) VALUES
(2, '2025-04-18', '2025-04-21', 450.00),
(4, '2025-05-01', '2025-05-08', 350.00); 

INSERT INTO BookingGuest (booking_id, guest_id) VALUES
(1, 1),
(1, 2),
(2, 3);

INSERT INTO Service (name, price) VALUES
('Spa', 30.00),
('Room Service', 15.00),
('Airport Transfer', 50.00),
('Gym', 40.00),
('Swimmig Pool', 20.00);

INSERT INTO BookingService (booking_id, service_id, quantity) VALUES
(1, 1, 2), 
(1, 2, 1), 
(2, 3, 1), 
(2, 4, 2), 
(2, 5, 1); 

INSERT INTO Staff (employee, role, is_available) VALUES
('Eleni', 'Reception', TRUE),
('Kostas', 'Housekeeping', FALSE),
('Anna', 'Reception', TRUE),
('Giannis', 'Housekeeping', TRUE),
('Eirini', 'Housekeeping',TRUE),
('Nikos', 'Housekeeping', FALSE),
('Dimitris', 'Driver', TRUE),
('Sofia', 'Driver', TRUE);

INSERT INTO BookingServiceStaff (booking_id, service_id, staff_id) VALUES
(1, 1, NULL),  
(1, 2, 2),     
(2, 3, 7),     
(2, 4, NULL),  
(2, 5, NULL);  

INSERT INTO Payment (booking_id, amount, payment_date, payment_method) VALUES
(1, 525.00, '2025-04-21', 'Credit Card'),
(2, 500.00, '2025-05-08', 'Cash');

DELIMITER //

CREATE PROCEDURE CalculateAndInsertPayment(IN p_booking_id INT)
BEGIN
    DECLARE v_room_id INT;
    DECLARE v_price_per_night DECIMAL(10,2);
    DECLARE v_check_in DATE;
    DECLARE v_check_out DATE;
    DECLARE v_nights INT;
    DECLARE v_room_cost DECIMAL(10,2);
    DECLARE v_services_cost DECIMAL(10,2);
    DECLARE v_total_cost DECIMAL(10,2);

    -- Ληψη στοιχείων κράτησης
    SELECT b.room_id, b.check_in_date, b.check_out_date
    INTO v_room_id, v_check_in, v_check_out
    FROM Booking b
    WHERE b.booking_id = p_booking_id;

    -- Υπολογισμος αριθμού διανυκτερεύσεων
    SET v_nights = DATEDIFF(v_check_out, v_check_in);

    -- Τιμη ανα διανυκτερευση
    SELECT rt.price_per_night
    INTO v_price_per_night
    FROM Room r
    JOIN RoomType rt ON r.room_type_id = rt.room_type_id
    WHERE r.room_id = v_room_id;

    -- Κοστος διαμονης
    SET v_room_cost = v_nights * v_price_per_night;

    -- Ενημερωση κρατησης με κοστος διαμονης μονο
    UPDATE Booking
    SET total_cost = v_room_cost
    WHERE booking_id = p_booking_id;

    -- Υπολογισμος κοστους υπηρεσιων
    SELECT IFNULL(SUM(bs.quantity * s.price), 0)
    INTO v_services_cost
    FROM BookingService bs
    JOIN Service s ON bs.service_id = s.service_id
    WHERE bs.booking_id = p_booking_id;

    -- Τελικο κοστος = διαμονη + υπηρεσιες
    SET v_total_cost = v_room_cost + v_services_cost;

    -- Εισαγωγη πληρωμης
    INSERT INTO Payment (booking_id, amount, payment_date, payment_method)
    VALUES (p_booking_id, v_total_cost, CURDATE(), 'Not Defined');
END //

DELIMITER ;

-- Procedure για ελεγχο διαθεσιμοτητας δωματιου
DELIMITER //

CREATE PROCEDURE CheckRoomAvailability(IN p_room_id INT, IN p_start DATE, IN p_end DATE)
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*) INTO v_count
    FROM Booking
    WHERE room_id = p_room_id
      AND (
          (check_in_date < p_end AND check_out_date > p_start)
      );

    IF v_count = 0 THEN
        SELECT 'Available' AS status;
    ELSE
        SELECT 'Not Available' AS status;
    END IF;
END //

DELIMITER ;

-- Procedure για πληρη καταχωριση κρατησης με πελατη
DELIMITER //

CREATE PROCEDURE MakeFullBooking(
    IN p_first_name VARCHAR(50),
    IN p_last_name VARCHAR(50),
    IN p_email VARCHAR(100),
    IN p_phone VARCHAR(20),
    IN p_room_id INT,
    IN p_check_in DATE,
    IN p_check_out DATE
)
BEGIN
    DECLARE v_guest_id INT;
    DECLARE v_booking_id INT;

    -- Εισαγωγη πελατη
    INSERT INTO Guest (first_name, last_name, email, phone)
    VALUES (p_first_name, p_last_name, p_email, p_phone);
    SET v_guest_id = LAST_INSERT_ID();

    -- Εισαγωγή κρατησης
    INSERT INTO Booking (room_id, check_in_date, check_out_date)
    VALUES (p_room_id, p_check_in, p_check_out);
    SET v_booking_id = LAST_INSERT_ID();

    -- Συνδεση κρατησης με πελατη
    INSERT INTO BookingGuest (booking_id, guest_id)
    VALUES (v_booking_id, v_guest_id);

END //

DELIMITER ;


-- Procedure για εμφανιση πληρους στοιχειων μιας κράτησης
DELIMITER //

CREATE PROCEDURE GetBookingInvoice(IN p_booking_id INT)
BEGIN
    -- Στοιχεια κράτησης
    SELECT b.booking_id, r.room_number, rt.name AS room_type,
           b.check_in_date, b.check_out_date, b.total_cost AS room_cost
    FROM Booking b
    JOIN Room r ON b.room_id = r.room_id
    JOIN RoomType rt ON r.room_type_id = rt.room_type_id
    WHERE b.booking_id = p_booking_id;

    -- Υπηρεσιες
    SELECT s.name AS service_name, bs.quantity, s.price, bs.quantity * s.price AS total_service_cost
    FROM BookingService bs
    JOIN Service s ON bs.service_id = s.service_id
    WHERE bs.booking_id = p_booking_id;

    -- Πληρωμη
    SELECT amount, payment_date, payment_method
    FROM Payment
    WHERE booking_id = p_booking_id;
END //

DELIMITER ;