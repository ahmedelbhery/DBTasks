
-- Insert sample data into EMPLOYEE table (at least 5 employees)
INSERT INTO Employee (SSN, Fname, Lname, BirthDate, Gender)
VALUES
(1001, 'Ali', 'Ahmed', '1985-02-10', 'M'),
(1003, 'Khalid', 'Hassan', '1988-07-22', 'M'),
(1005, 'Omar', 'Youssef', '1992-01-30', 'M');
GO
-- Insert departments
INSERT INTO Department (DNUM, DName, Location, MgrSSN)
VALUES
(1, 'HR', 'Cairo', 1001),
(2, 'IT', 'Alexandria', 1003),
(3, 'Finance', 'Giza', 1005);
GO

-- Update DNUM for managers now that departments exist
UPDATE Employee SET DNUM = 1 WHERE SSN = 1001;
UPDATE Employee SET DNUM = 2 WHERE SSN = 1003;
UPDATE Employee SET DNUM = 3 WHERE SSN = 1005;
GO

-- Update SuperSSN for managers now that departments exist
UPDATE Employee SET SupervisorSSN = 1002 WHERE SSN = 1001;
UPDATE Employee SET SupervisorSSN = 1005 WHERE SSN = 1003;
UPDATE Employee SET SupervisorSSN = 1004 WHERE SSN = 1005;

-- Insert remaining employees
INSERT INTO Employee (SSN, Fname, Lname, BirthDate, Gender, DNUM, SupervisorSSN)
VALUES
(1002, 'Sara', 'Mahmoud', '1990-05-12', 'F', 1, 1001),
(1004, 'Nora', 'Said', '1995-09-05', 'F', 2, 1003);
GO


-- Update an employee's department
UPDATE Employee
SET DNUM = 3
WHERE SSN = 1002;


-- Delete a dependent record
INSERT INTO Dependent (ESSN, DependentName, Gender, BirthDate)
VALUES
(1001, 'Laila', 'F', '2010-10-10'),
(1002, 'Yousef', 'M', '2012-03-05');

DELETE FROM Dependent
WHERE ESSN = 1002 AND DependentName = 'Yousef';


-- Retrieve all employees working in a specific department
SELECT E.SSN, E.Fname, E.Lname, D.DName
FROM Employee E JOIN Department D 
ON E.DNUM = D.DNUM
WHERE D.DName = 'HR';


-- Find all employees and their project assignments with working hours
INSERT INTO Project (PNumber, Pname, DNUM)
VALUES
(200, 'Payroll System', 1),
(201, 'Web Portal', 2),
(202, 'Budget Report', 3);

INSERT INTO Works_On (ESSN, PNO, WorkHours)
VALUES
(1001, 200, 10),
(1002, 200, 15),
(1003, 201, 20),
(1004, 201, 25),
(1005, 202, 30);

SELECT E.Fname, E.Lname, P.Pname, W.WorkHours
FROM Employee E
JOIN Works_On W ON E.SSN = W.ESSN
JOIN Project P ON W.PNO = P.PNumber;




