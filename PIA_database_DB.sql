/* ============================================================
   PIA AIRLINE MANAGEMENT DATABASE
   Database Systems Assignment - SQL Server

   Project:
   Design and Implementation of a Secure Transactional
   Database System for Pakistan International Airlines (PIA)

   ============================================================ */


/* ============================================================
   PART 1
   CREATE DATABASE
   ============================================================ */

-- Create the PIA database
CREATE DATABASE PIA_Airline_DB;
GO

-- Select the PIA database
USE PIA_Airline_DB;
GO


/* ============================================================
   PART 2
   CREATE TABLES
   ============================================================

   Main entities:

   1. Departments
   2. Employees
   3. Airports
   4. Aircraft
   5. Flights
   6. Passengers
   7. Bookings
   8. Payments
   9. Maintenance
   10. AuditLog
   11. BookingLog

   Primary Key = uniquely identifies a record
   Foreign Key = connects two tables
   ============================================================ */


/* ------------------------------------------------------------
   TABLE 1: Departments
   ------------------------------------------------------------ */

CREATE TABLE Departments
(
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,

    DepartmentName VARCHAR(100) NOT NULL,

    -- Department name cannot be duplicated
    CONSTRAINT UQ_DepartmentName
        UNIQUE (DepartmentName)
);
GO


/* ------------------------------------------------------------
   TABLE 2: Employees
   ------------------------------------------------------------ */

CREATE TABLE Employees
(
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,

    EmployeeName VARCHAR(100) NOT NULL,

    JobTitle VARCHAR(100) NOT NULL,

    DepartmentID INT NOT NULL,

    HireDate DATE DEFAULT GETDATE(),

    Salary DECIMAL(12,2),

    -- Employee belongs to a department
    CONSTRAINT FK_Employee_Department
        FOREIGN KEY (DepartmentID)
        REFERENCES Departments(DepartmentID),

    -- Salary cannot be negative
    CONSTRAINT CK_EmployeeSalary
        CHECK (Salary >= 0)
);
GO


/* ------------------------------------------------------------
   TABLE 3: Airports
   ------------------------------------------------------------ */

CREATE TABLE Airports
(
    AirportID INT IDENTITY(1,1) PRIMARY KEY,

    AirportCode CHAR(3) NOT NULL,

    AirportName VARCHAR(100) NOT NULL,

    City VARCHAR(100) NOT NULL,

    Country VARCHAR(100) NOT NULL,

    -- Example: KHI, LHE, ISB
    CONSTRAINT UQ_AirportCode
        UNIQUE (AirportCode)
);
GO


/* ------------------------------------------------------------
   TABLE 4: Aircraft
   ------------------------------------------------------------ */

CREATE TABLE Aircraft
(
    AircraftID INT IDENTITY(1,1) PRIMARY KEY,

    RegistrationNo VARCHAR(20) NOT NULL,

    AircraftModel VARCHAR(50) NOT NULL,

    Capacity INT NOT NULL,

    AircraftStatus VARCHAR(30) DEFAULT 'Active',

    -- Registration number must be unique
    CONSTRAINT UQ_RegistrationNo
        UNIQUE (RegistrationNo),

    -- Capacity must be greater than zero
    CONSTRAINT CK_AircraftCapacity
        CHECK (Capacity > 0),

    -- Only these statuses are allowed
    CONSTRAINT CK_AircraftStatus
        CHECK
        (
            AircraftStatus IN
            ('Active', 'Maintenance', 'Retired')
        )
);
GO


/* ------------------------------------------------------------
   TABLE 5: Flights
   ------------------------------------------------------------ */

CREATE TABLE Flights
(
    FlightID INT IDENTITY(1,1) PRIMARY KEY,

    FlightNumber VARCHAR(20) NOT NULL,

    AircraftID INT NOT NULL,

    DepartureAirportID INT NOT NULL,

    ArrivalAirportID INT NOT NULL,

    DepartureDateTime DATETIME NOT NULL,

    ArrivalDateTime DATETIME NOT NULL,

    FlightStatus VARCHAR(30) DEFAULT 'Scheduled',

    -- Connect flight with aircraft
    CONSTRAINT FK_Flight_Aircraft
        FOREIGN KEY (AircraftID)
        REFERENCES Aircraft(AircraftID),

    -- Departure airport
    CONSTRAINT FK_Flight_DepartureAirport
        FOREIGN KEY (DepartureAirportID)
        REFERENCES Airports(AirportID),

    -- Arrival airport
    CONSTRAINT FK_Flight_ArrivalAirport
        FOREIGN KEY (ArrivalAirportID)
        REFERENCES Airports(AirportID),

    -- Arrival must be after departure
    CONSTRAINT CK_FlightTime
        CHECK (ArrivalDateTime > DepartureDateTime),

    -- Flight status
    CONSTRAINT CK_FlightStatus
        CHECK
        (
            FlightStatus IN
            ('Scheduled', 'Boarding', 'Departed',
             'Arrived', 'Cancelled', 'Delayed')
        )
);
GO


/* ------------------------------------------------------------
   TABLE 6: Passengers
   ------------------------------------------------------------ */

CREATE TABLE Passengers
(
    PassengerID INT IDENTITY(1,1) PRIMARY KEY,

    PassengerName VARCHAR(100) NOT NULL,

    CNIC VARCHAR(20) NOT NULL,

    Phone VARCHAR(20),

    Email VARCHAR(100),

    PassportNo VARCHAR(30),

    -- CNIC must be unique
    CONSTRAINT UQ_PassengerCNIC
        UNIQUE (CNIC)
);
GO


/* ------------------------------------------------------------
   TABLE 7: Bookings
   ------------------------------------------------------------ */

CREATE TABLE Bookings
(
    BookingID INT IDENTITY(1,1) PRIMARY KEY,

    PassengerID INT NOT NULL,

    FlightID INT NOT NULL,

    SeatNumber VARCHAR(10) NOT NULL,

    BookingDate DATETIME DEFAULT GETDATE(),

    BookingStatus VARCHAR(30) DEFAULT 'Confirmed',

    Fare DECIMAL(12,2) NOT NULL,

    -- Connect passenger with booking
    CONSTRAINT FK_Booking_Passenger
        FOREIGN KEY (PassengerID)
        REFERENCES Passengers(PassengerID),

    -- Connect flight with booking
    CONSTRAINT FK_Booking_Flight
        FOREIGN KEY (FlightID)
        REFERENCES Flights(FlightID),

    -- Fare cannot be negative
    CONSTRAINT CK_BookingFare
        CHECK (Fare >= 0),

    -- Booking status
    CONSTRAINT CK_BookingStatus
        CHECK
        (
            BookingStatus IN
            ('Confirmed', 'Cancelled', 'Completed')
        ),

    -- Same seat cannot be booked twice on same flight
    CONSTRAINT UQ_FlightSeat
        UNIQUE (FlightID, SeatNumber)
);
GO


/* ------------------------------------------------------------
   TABLE 8: Payments
   ------------------------------------------------------------ */

CREATE TABLE Payments
(
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,

    BookingID INT NOT NULL,

    PaymentDate DATETIME DEFAULT GETDATE(),

    Amount DECIMAL(12,2) NOT NULL,

    PaymentMethod VARCHAR(30) NOT NULL,

    PaymentStatus VARCHAR(30) DEFAULT 'Paid',

    -- Connect payment with booking
    CONSTRAINT FK_Payment_Booking
        FOREIGN KEY (BookingID)
        REFERENCES Bookings(BookingID),

    CONSTRAINT CK_PaymentAmount
        CHECK (Amount > 0)
);
GO


/* ------------------------------------------------------------
   TABLE 9: Maintenance
   ------------------------------------------------------------ */

CREATE TABLE Maintenance
(
    MaintenanceID INT IDENTITY(1,1) PRIMARY KEY,

    AircraftID INT NOT NULL,

    MaintenanceType VARCHAR(100) NOT NULL,

    MaintenanceDate DATE DEFAULT GETDATE(),

    Description VARCHAR(500),

    Cost DECIMAL(12,2),

    MaintenanceStatus VARCHAR(30) DEFAULT 'Completed',

    EmployeeID INT,

    -- Aircraft being maintained
    CONSTRAINT FK_Maintenance_Aircraft
        FOREIGN KEY (AircraftID)
        REFERENCES Aircraft(AircraftID),

    -- Employee responsible for maintenance
    CONSTRAINT FK_Maintenance_Employee
        FOREIGN KEY (EmployeeID)
        REFERENCES Employees(EmployeeID),

    CONSTRAINT CK_MaintenanceCost
        CHECK (Cost >= 0)
);
GO


/* ============================================================
   TABLE 10: BOOKING LOG
   Used by trigger for INSERT/UPDATE/DELETE logging
   ============================================================ */

CREATE TABLE BookingLog
(
    LogID INT IDENTITY(1,1) PRIMARY KEY,

    BookingID INT,

    ActionType VARCHAR(30),

    ActionDate DATETIME DEFAULT GETDATE(),

    Description VARCHAR(500)
);
GO


/* ============================================================
   TABLE 11: AUDIT LOG
   Used for database auditing
   ============================================================ */

CREATE TABLE AuditLog
(
    AuditID INT IDENTITY(1,1) PRIMARY KEY,

    TableName VARCHAR(100),

    ActionType VARCHAR(30),

    RecordID INT,

    ActionDate DATETIME DEFAULT GETDATE(),

    Description VARCHAR(500)
);
GO


/* ============================================================
   PART 3
   INSERT SAMPLE DATA
   ============================================================ */


/* ------------------------------------------------------------
   Insert Departments
   ------------------------------------------------------------ */

INSERT INTO Departments
(DepartmentName)
VALUES
('Flight Operations'),
('Engineering'),
('Maintenance'),
('Human Resources'),
('Finance'),
('IT');

GO


/* ------------------------------------------------------------
   Insert Employees
   ------------------------------------------------------------ */

INSERT INTO Employees
(EmployeeName, JobTitle, DepartmentID, Salary)
VALUES
('Ahmed Khan', 'Pilot', 1, 250000),
('Ali Raza', 'Aircraft Engineer', 2, 220000),
('Usman Ahmed', 'Maintenance Engineer', 3, 180000),
('Sara Khan', 'HR Officer', 4, 120000),
('Hamza Ali', 'Finance Officer', 5, 130000),
('Bilal Ahmed', 'IT Officer', 6, 150000);

GO


/* ------------------------------------------------------------
   Insert Airports
   ------------------------------------------------------------ */

INSERT INTO Airports
(AirportCode, AirportName, City, Country)
VALUES
('KHI', 'Jinnah International Airport', 'Karachi', 'Pakistan'),
('LHE', 'Allama Iqbal International Airport', 'Lahore', 'Pakistan'),
('ISB', 'Islamabad International Airport', 'Islamabad', 'Pakistan'),
('DXB', 'Dubai International Airport', 'Dubai', 'UAE'),
('JED', 'King Abdulaziz International Airport', 'Jeddah', 'Saudi Arabia');

GO


/* ------------------------------------------------------------
   Insert Aircraft
   ------------------------------------------------------------ */

INSERT INTO Aircraft
(RegistrationNo, AircraftModel, Capacity, AircraftStatus)
VALUES
('AP-BLA', 'Boeing 777-300ER', 393, 'Active'),
('AP-BLB', 'Boeing 777-200ER', 329, 'Active'),
('AP-BLC', 'Airbus A320', 180, 'Maintenance'),
('AP-BLD', 'ATR 72', 70, 'Active');

GO


/* ------------------------------------------------------------
   Insert Flights
   ------------------------------------------------------------ */

INSERT INTO Flights
(
    FlightNumber,
    AircraftID,
    DepartureAirportID,
    ArrivalAirportID,
    DepartureDateTime,
    ArrivalDateTime,
    FlightStatus
)
VALUES
(
    'PK301',
    1,
    1,
    3,
    '2026-12-01 08:00',
    '2026-12-01 10:00',
    'Scheduled'
),

(
    'PK302',
    2,
    3,
    1,
    '2026-12-02 15:00',
    '2026-12-02 17:00',
    'Scheduled'
),

(
    'PK203',
    3,
    1,
    2,
    '2026-12-03 09:00',
    '2026-12-03 11:00',
    'Scheduled'
),

(
    'PK701',
    4,
    1,
    4,
    '2026-12-04 18:00',
    '2026-12-04 20:30',
    'Scheduled'
);

GO


/* ------------------------------------------------------------
   Insert Passengers
   ------------------------------------------------------------ */

INSERT INTO Passengers
(
    PassengerName,
    CNIC,
    Phone,
    Email,
    PassportNo
)
VALUES
(
    'Muhammad Ali',
    '42101-1234567-1',
    '03001234567',
    'ali@gmail.com',
    'PK123456'
),

(
    'Usman Khan',
    '42101-2345678-2',
    '03111234567',
    'usman@gmail.com',
    'PK234567'
),

(
    'Ahmed Raza',
    '42101-3456789-3',
    '03221234567',
    'ahmed@gmail.com',
    'PK345678'
);

GO


/* ------------------------------------------------------------
   Insert Bookings
   ------------------------------------------------------------ */

INSERT INTO Bookings
(
    PassengerID,
    FlightID,
    SeatNumber,
    Fare
)
VALUES
(1, 1, '12A', 25000),
(2, 1, '12B', 25000),
(3, 2, '15C', 22000);

GO


/* ------------------------------------------------------------
   Insert Payments
   ------------------------------------------------------------ */

INSERT INTO Payments
(
    BookingID,
    Amount,
    PaymentMethod
)
VALUES
(1, 25000, 'Credit Card'),
(2, 25000, 'Bank Transfer'),
(3, 22000, 'Cash');

GO


/* ------------------------------------------------------------
   Insert Maintenance Record
   ------------------------------------------------------------ */

INSERT INTO Maintenance
(
    AircraftID,
    MaintenanceType,
    Description,
    Cost,
    EmployeeID
)
VALUES
(
    3,
    'Engine Inspection',
    'Routine engine inspection',
    500000,
    3
);

GO


/* ============================================================
   PART 4
   INDEXES
   ============================================================

   Indexes help SQL Server find records faster.
   ============================================================ */


/* Search flights by flight number */
CREATE INDEX IX_Flights_FlightNumber
ON Flights(FlightNumber);
GO


/* Search bookings by passenger */
CREATE INDEX IX_Bookings_PassengerID
ON Bookings(PassengerID);
GO


/* Search bookings by flight */
CREATE INDEX IX_Bookings_FlightID
ON Bookings(FlightID);
GO


/* Search maintenance by aircraft */
CREATE INDEX IX_Maintenance_AircraftID
ON Maintenance(AircraftID);
GO


/* Search flights by departure time */
CREATE INDEX IX_Flights_DepartureDateTime
ON Flights(DepartureDateTime);
GO


/* ============================================================
   PART 5
   STORED PROCEDURES
   ============================================================ */


/* ------------------------------------------------------------
   PROCEDURE 1
   Insert a new passenger
   ------------------------------------------------------------ */

CREATE PROCEDURE sp_AddPassenger
    @PassengerName VARCHAR(100),
    @CNIC VARCHAR(20),
    @Phone VARCHAR(20),
    @Email VARCHAR(100),
    @PassportNo VARCHAR(30)
AS
BEGIN

    -- Start error handling
    BEGIN TRY

        INSERT INTO Passengers
        (
            PassengerName,
            CNIC,
            Phone,
            Email,
            PassportNo
        )
        VALUES
        (
            @PassengerName,
            @CNIC,
            @Phone,
            @Email,
            @PassportNo
        );

        PRINT 'Passenger added successfully.';

    END TRY

    BEGIN CATCH

        PRINT 'Error: ' + ERROR_MESSAGE();

    END CATCH

END;
GO


/* ------------------------------------------------------------
   PROCEDURE 2
   Book a flight
   Uses transaction and error handling
   ------------------------------------------------------------ */

CREATE PROCEDURE sp_BookFlight
    @PassengerID INT,
    @FlightID INT,
    @SeatNumber VARCHAR(10),
    @Fare DECIMAL(12,2)
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        -- Start transaction
        BEGIN TRANSACTION;

        -- Insert booking
        INSERT INTO Bookings
        (
            PassengerID,
            FlightID,
            SeatNumber,
            Fare
        )
        VALUES
        (
            @PassengerID,
            @FlightID,
            @SeatNumber,
            @Fare
        );

        -- If everything works, save changes
        COMMIT TRANSACTION;

        PRINT 'Flight booked successfully.';

    END TRY

    BEGIN CATCH

        -- If something goes wrong,
        -- undo the transaction
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'Booking failed.';
        PRINT ERROR_MESSAGE();

    END CATCH

END;
GO


/* ------------------------------------------------------------
   PROCEDURE 3
   Update passenger information
   ------------------------------------------------------------ */

CREATE PROCEDURE sp_UpdatePassenger
    @PassengerID INT,
    @Phone VARCHAR(20),
    @Email VARCHAR(100)
AS
BEGIN

    UPDATE Passengers

    SET
        Phone = @Phone,
        Email = @Email

    WHERE PassengerID = @PassengerID;

    PRINT 'Passenger updated successfully.';

END;
GO


/* ------------------------------------------------------------
   PROCEDURE 4
   Update flight status
   This is the airline equivalent of updating a record.
   ------------------------------------------------------------ */

CREATE PROCEDURE sp_UpdateFlightStatus
    @FlightID INT,
    @FlightStatus VARCHAR(30)
AS
BEGIN

    UPDATE Flights

    SET FlightStatus = @FlightStatus

    WHERE FlightID = @FlightID;

    PRINT 'Flight status updated.';

END;
GO


/* ------------------------------------------------------------
   PROCEDURE 5
   Retrieve passenger itinerary
   ------------------------------------------------------------ */

CREATE PROCEDURE sp_GetPassengerItinerary
    @PassengerID INT
AS
BEGIN

    SELECT
        P.PassengerName,
        F.FlightNumber,
        A1.AirportCode AS Departure,
        A2.AirportCode AS Arrival,
        F.DepartureDateTime,
        F.ArrivalDateTime,
        B.SeatNumber,
        B.Fare,
        B.BookingStatus

    FROM Bookings B

    INNER JOIN Passengers P
        ON B.PassengerID = P.PassengerID

    INNER JOIN Flights F
        ON B.FlightID = F.FlightID

    INNER JOIN Airports A1
        ON F.DepartureAirportID = A1.AirportID

    INNER JOIN Airports A2
        ON F.ArrivalAirportID = A2.AirportID

    WHERE B.PassengerID = @PassengerID;

END;
GO


/* ------------------------------------------------------------
   PROCEDURE 6
   Delete a flight
   Transaction + error handling
   ------------------------------------------------------------ */

CREATE PROCEDURE sp_DeleteFlight
    @FlightID INT
AS
BEGIN

    BEGIN TRY

        BEGIN TRANSACTION;

        -- Delete the flight
        DELETE FROM Flights
        WHERE FlightID = @FlightID;

        COMMIT TRANSACTION;

        PRINT 'Flight deleted successfully.';

    END TRY

    BEGIN CATCH

        -- Undo changes if there is an error
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'Flight cannot be deleted.';
        PRINT ERROR_MESSAGE();

    END CATCH

END;
GO


/* ============================================================
   TEST STORED PROCEDURES
   ============================================================ */


/* Add passenger */
EXEC sp_AddPassenger
    'Hassan Ahmed',
    '42101-4567890-4',
    '03331234567',
    'hassan@gmail.com',
    'PK456789';
GO


/* Update passenger */
EXEC sp_UpdatePassenger
    1,
    '03009999999',
    'newemail@gmail.com';
GO


/* Get passenger itinerary */
EXEC sp_GetPassengerItinerary 1;
GO


/* Update flight status */
EXEC sp_UpdateFlightStatus
    1,
    'Boarding';
GO


/* ============================================================
   PART 6
   USER DEFINED FUNCTIONS
   ============================================================ */


/* ------------------------------------------------------------
   FUNCTION 1
   Scalar Function

   Calculates loyalty points based on fare.

   This is the PIA equivalent of the assignment's
   scalar calculation function.
   ------------------------------------------------------------ */

CREATE FUNCTION fn_CalculateLoyaltyPoints
(
    @Fare DECIMAL(12,2)
)
RETURNS INT
AS
BEGIN

    DECLARE @Points INT;

    -- 1 point for every Rs.100 spent
    SET @Points = FLOOR(@Fare / 100);

    RETURN @Points;

END;
GO


/* Test scalar function */
SELECT
    dbo.fn_CalculateLoyaltyPoints(25000)
    AS LoyaltyPoints;
GO


/* ------------------------------------------------------------
   FUNCTION 2
   Table-Valued Function

   Returns all flights booked by a passenger.
   ------------------------------------------------------------ */

CREATE FUNCTION fn_PassengerFlights
(
    @PassengerID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT

        B.BookingID,
        F.FlightNumber,
        B.SeatNumber,
        B.Fare,
        F.DepartureDateTime,
        F.ArrivalDateTime,
        B.BookingStatus

    FROM Bookings B

    INNER JOIN Flights F
        ON B.FlightID = F.FlightID

    WHERE B.PassengerID = @PassengerID
);
GO


/* Test table-valued function */

SELECT *
FROM dbo.fn_PassengerFlights(1);
GO


/* ------------------------------------------------------------
   FUNCTION 3
   Multi-Statement Table-Valued Function

   Finds passengers who have spent a high amount.
   ------------------------------------------------------------ */

CREATE FUNCTION fn_HighValuePassengers
(
    @MinimumAmount DECIMAL(12,2)
)
RETURNS @Result TABLE
(
    PassengerID INT,
    PassengerName VARCHAR(100),
    TotalSpent DECIMAL(12,2)
)
AS
BEGIN

    INSERT INTO @Result

    SELECT
        P.PassengerID,
        P.PassengerName,
        SUM(B.Fare) AS TotalSpent

    FROM Passengers P

    INNER JOIN Bookings B
        ON P.PassengerID = B.PassengerID

    GROUP BY
        P.PassengerID,
        P.PassengerName

    HAVING SUM(B.Fare) >= @MinimumAmount;

    RETURN;

END;
GO


/* Test multi-statement function */

SELECT *
FROM dbo.fn_HighValuePassengers(20000);
GO


/* ============================================================
   PART 7
   TRIGGERS
   ============================================================ */


/* ------------------------------------------------------------
   TRIGGER 1
   Booking INSERT logging

   INSERTED contains the new record.
   ------------------------------------------------------------ */

CREATE TRIGGER trg_Booking_Insert
ON Bookings
AFTER INSERT
AS
BEGIN

    INSERT INTO BookingLog
    (
        BookingID,
        ActionType,
        Description
    )

    SELECT
        BookingID,
        'INSERT',
        'New booking created.'

    FROM INSERTED;

END;
GO


/* ------------------------------------------------------------
   TRIGGER 2
   Booking UPDATE logging

   DELETED = old record
   INSERTED = new record
   ------------------------------------------------------------ */

CREATE TRIGGER trg_Booking_Update
ON Bookings
AFTER UPDATE
AS
BEGIN

    INSERT INTO BookingLog
    (
        BookingID,
        ActionType,
        Description
    )

    SELECT
        I.BookingID,
        'UPDATE',
        'Booking information updated.'

    FROM INSERTED I;

END;
GO


/* ------------------------------------------------------------
   TRIGGER 3
   Prevent deletion of confirmed bookings

   This protects important transactional data.
   ------------------------------------------------------------ */

CREATE TRIGGER trg_PreventConfirmedBookingDelete
ON Bookings
INSTEAD OF DELETE
AS
BEGIN

    IF EXISTS
    (
        SELECT 1
        FROM DELETED
        WHERE BookingStatus = 'Confirmed'
    )
    BEGIN

        RAISERROR
        (
            'Confirmed bookings cannot be deleted.',
            16,
            1
        );

        RETURN;

    END;

    -- Delete only bookings that are not confirmed
    DELETE FROM Bookings

    WHERE BookingID IN
    (
        SELECT BookingID
        FROM DELETED
    );

END;
GO


/* ------------------------------------------------------------
   TRIGGER 4
   Payment update audit

   Uses INSERTED and DELETED.
   ------------------------------------------------------------ */

CREATE TRIGGER trg_Payment_Audit
ON Payments
AFTER UPDATE
AS
BEGIN

    INSERT INTO AuditLog
    (
        TableName,
        ActionType,
        RecordID,
        Description
    )

    SELECT
        'Payments',
        'UPDATE',
        I.PaymentID,
        'Payment record updated.'

    FROM INSERTED I;

END;
GO


/* ============================================================
   TEST TRIGGERS
   ============================================================ */


/* Update booking status */
UPDATE Bookings

SET BookingStatus = 'Completed'

WHERE BookingID = 1;
GO


/* View booking log */
SELECT *
FROM BookingLog;
GO


/* View audit log */
SELECT *
FROM AuditLog;
GO


/* ============================================================
   PART 8
   QUERY OPTIMIZATION
   ============================================================ */


/* ------------------------------------------------------------
   Example optimized query

   We use only required columns and proper INNER JOINs.
   Indexes were created on commonly searched columns.
   ------------------------------------------------------------ */

SELECT

    F.FlightNumber,
    A1.AirportCode AS Departure,
    A2.AirportCode AS Arrival,
    F.DepartureDateTime,
    F.FlightStatus

FROM Flights F

INNER JOIN Airports A1
    ON F.DepartureAirportID = A1.AirportID

INNER JOIN Airports A2
    ON F.ArrivalAirportID = A2.AirportID

WHERE F.FlightStatus = 'Scheduled'

ORDER BY F.DepartureDateTime;
GO


/* ------------------------------------------------------------
   Another optimized query

   Find bookings for one passenger.
   IX_Bookings_PassengerID helps this query.
   ------------------------------------------------------------ */

SELECT

    B.BookingID,
    P.PassengerName,
    F.FlightNumber,
    B.SeatNumber,
    B.Fare

FROM Bookings B

INNER JOIN Passengers P
    ON B.PassengerID = P.PassengerID

INNER JOIN Flights F
    ON B.FlightID = F.FlightID

WHERE B.PassengerID = 1;
GO


/* ============================================================
   EXECUTION PLAN
   ============================================================

   In SSMS:

   Press:
   CTRL + M

   Then execute the query.

   SQL Server will show the Actual Execution Plan.

   Compare queries before and after indexes.

   You can take a screenshot for your assignment.
   ============================================================ */


/* ============================================================
   PART 9
   SECURITY & ROLES
   ============================================================

   NOTE:
   This section requires SQL Server permissions.

   It creates:
   1. Login
   2. Database User
   3. Roles
   4. GRANT
   5. DENY
   6. REVOKE
   ============================================================ */


/* ------------------------------------------------------------
   CREATE DATABASE ROLES
   ------------------------------------------------------------ */

USE PIA_Airline_DB;
GO


/* Manager role */
CREATE ROLE PIA_Manager;
GO


/* Booking staff role */
CREATE ROLE PIA_BookingStaff;
GO


/* Maintenance staff role */
CREATE ROLE PIA_MaintenanceStaff;
GO


/* ------------------------------------------------------------
   GIVE PERMISSIONS
   ------------------------------------------------------------ */


/* Manager can read and modify important tables */

GRANT SELECT, INSERT, UPDATE, DELETE
ON Passengers
TO PIA_Manager;

GRANT SELECT, INSERT, UPDATE, DELETE
ON Bookings
TO PIA_Manager;

GRANT SELECT, INSERT, UPDATE, DELETE
ON Flights
TO PIA_Manager;

GO


/* Booking staff can view passengers and flights */

GRANT SELECT
ON Passengers
TO PIA_BookingStaff;

GRANT SELECT
ON Flights
TO PIA_BookingStaff;

GRANT SELECT, INSERT, UPDATE
ON Bookings
TO PIA_BookingStaff;

GO


/* Maintenance staff can view aircraft */

GRANT SELECT
ON Aircraft
TO PIA_MaintenanceStaff;

GRANT SELECT, INSERT, UPDATE
ON Maintenance
TO PIA_MaintenanceStaff;

GO


/* ------------------------------------------------------------
   DENY
   Booking staff cannot delete bookings.
   ------------------------------------------------------------ */

DENY DELETE
ON Bookings
TO PIA_BookingStaff;
GO


/* ------------------------------------------------------------
   REVOKE
   Example of removing a permission.
   ------------------------------------------------------------ */

REVOKE UPDATE
ON Passengers
FROM PIA_BookingStaff;
GO


/* ============================================================
   CREATE SQL SERVER LOGIN
   ============================================================

   This part must be executed by an administrator.

   Change the password before real use.
   ============================================================ */

USE master;
GO

CREATE LOGIN PIA_Admin_Login
WITH PASSWORD = 'PIA_Project@12345';
GO


/* ============================================================
   CREATE DATABASE USER FOR LOGIN
   ============================================================ */

USE PIA_Airline_DB;
GO

CREATE USER PIA_Admin_User
FOR LOGIN PIA_Admin_Login;
GO


/* Put user into manager role */

ALTER ROLE PIA_Manager
ADD MEMBER PIA_Admin_User;
GO


/* ============================================================
   SECURITY TEST
   ============================================================ */


/* Show database users */

SELECT
    name,
    type_desc

FROM sys.database_principals

WHERE type IN ('S', 'U', 'G');
GO


/* Show database roles */

SELECT
    name

FROM sys.database_principals

WHERE type = 'R';
GO


/* ============================================================
   FINAL DATABASE CHECK
   ============================================================ */


/* Show all tables */

SELECT
    TABLE_NAME

FROM INFORMATION_SCHEMA.TABLES

WHERE TABLE_TYPE = 'BASE TABLE';
GO


/* Show passengers */

SELECT *
FROM Passengers;
GO


/* Show aircraft */

SELECT *
FROM Aircraft;
GO


/* Show flights */

SELECT *
FROM Flights;
GO


/* Show bookings */

SELECT *
FROM Bookings;
GO


/* Show payments */

SELECT *
FROM Payments;
GO


/* ============================================================
   END OF PIA DATABASE PROJECT
   ============================================================ */
