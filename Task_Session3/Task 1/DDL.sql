
-- Step 1: Create DB 
create database Company
Go
use Company
Go
-- Step 2: Create EMPLOYEE 
 CREATE TABLE Employee (
    SSN INT PRIMARY KEY,
    Fname VARCHAR(50) NOT NULL,
    Lname VARCHAR(50) NOT NULL,
    BirthDate DATE NOT NULL,
    Gender CHAR(1) CHECK (Gender IN ('M', 'F'))
 );
 GO-- Step 3: Create DEPARTMENT
 CREATE TABLE Department (
    DNUM INT PRIMARY KEY,
    DName VARCHAR(50) UNIQUE NOT NULL,
    Location VARCHAR(100) NOT NULL,
    MgrSSN INT UNIQUE NOT NULL,
    FOREIGN KEY (MgrSSN) REFERENCES Employee(SSN)
 );
 GO
-- Step 3: Alter Employee to add relationships
ALTER TABLE Employee
ADD DNUM INT NULL,
    SupervisorSSN INT NULL,
    FOREIGN KEY (DNUM) REFERENCES Department(DNUM),
    FOREIGN KEY (SupervisorSSN) REFERENCES Employee(SSN);
GO
-- 4. Create DEPENDENT
CREATE TABLE Dependent (
    ESSN INT,
    DependentName VARCHAR(50),
    Gender CHAR(1) CHECK (Gender IN ('M', 'F')),
    BirthDate DATE,
    PRIMARY KEY (ESSN, DependentName),
    FOREIGN KEY (ESSN) REFERENCES Employee(SSN) ON DELETE CASCADE
);
Go
-- 5. Create PROJECT
CREATE TABLE Project (
    PNumber INT PRIMARY KEY,
    Pname VARCHAR(100) NOT NULL,
    DNUM INT NOT NULL,
    FOREIGN KEY (DNUM) REFERENCES Department(DNUM)
);
Go
-- 6. Create WORKS_ON
CREATE TABLE Works_On (
    ESSN INT,
    PNO INT,
    WorkHours DECIMAL(5,2),
    PRIMARY KEY (ESSN, PNO),
    FOREIGN KEY (ESSN) REFERENCES Employee(SSN),
    FOREIGN KEY (PNO) REFERENCES Project(PNumber)
);
