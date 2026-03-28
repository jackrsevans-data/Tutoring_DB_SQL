/* SQL Project - J Evans */

-- Access School DB
use school;

-- 1) Total number of students.
Select count(*) as [Student Count] from Students;


--  2) City-wise student count (descending).
Select city, count(student_id) as [Students per city] from Students group by city order by [Students per city] desc, city asc;

--  3) Total revenue collected.
Select sum(amount) as [Total Revenue Collected] from Payments;

--  4) Monthly revenue (YYYY-MM).
Select FORMAT(payment_date,'yyyy-MM') as [Payment Month], sum(amount) as [Total Monthly Revenue] from Payments Group by FORMAT(payment_date,'yyyy-MM') order by [Payment Month];

--  5) Outstanding by enrollment (Course price − sum of payments).
Select E.enroll_id, C.course_name, (C.price - Sum(P.amount)) as [Remaining Balance] from Enrollments as E
	left join ClassBatches as CB ON E.batch_id = CB.batch_id
	left join Courses as C ON CB.course_id = C.course_id
	left join Payments as P ON E.enroll_id = P.enroll_id
GROUP BY E.enroll_id, C.course_name, C.Price;


--  6) Top 3 courses by revenue.
WITH CourseRevenue AS (
	Select
		C.course_name as [Course Name],
		sum(P.amount) as Revenue
	from Courses C
	left join ClassBatches CB
		ON C.course_id = CB.course_id
	left join Enrollments E 
		ON CB.batch_id = E.batch_id
	left join Payments P
		ON E.enroll_id = P.enroll_id
	Group by C.course_name, C.Price
	
) 
Select Top 3 * from CourseRevenue Order by Revenue Desc;


--  7) Teacher with highest revenue attribution.
WITH TeacherRevenue AS (
	Select
		T.teacher_name as [Teacher Name],
		T.teacher_id as [Teacher ID],
		ISNULL(sum(P.amount),0) as Revenue
	from  Teachers T
	left join ClassBatches CB
		ON T.teacher_id = CB.teacher_id
	left join Enrollments E 
		ON CB.batch_id = E.batch_id
	left join Payments P
		ON E.enroll_id = P.enroll_id
	Group by T.teacher_name,T.teacher_id
	
) 
Select TOP 1 * from TeacherRevenue Order by Revenue Desc;

--  8) Average class size per batch.
Select AVG(BatchCount) as [Average Batch Size] From (
	Select batch_id, Count(student_id) as BatchCount From Enrollments
	Group by batch_id
) BatchSizeTable;


--  9) Overall attendance rate (% present).
Select round(AVG(PupilAvgAttend),2) as [Average Attendance] From (
	Select student_id, AVG(cast(present as float)*100) as PupilAvgAttend from Attendance
	group by student_id
) AttendanceTable;

-- 10) Course with maximum enrollments.
WITH CourseEnrollments AS (
	Select
		C.course_name as [Course Name],
		Count(E.enroll_id) as [Number Enrolled]
	from Courses C
	left join ClassBatches CB
		ON C.course_id = CB.course_id
	left join Enrollments E 
		ON CB.batch_id = E.batch_id
	Group by C.course_name
	
) 
Select Top 1 * from CourseEnrollments Order by [Number Enrolled] Desc;

-- 11) Students enrolled in 2 or more batches.
Select full_name as [Students on multiple courses] from Students where student_id in (
	Select student_id as Class_count from Enrollments group by student_id having count(batch_id) >1
) order by [Students on multiple courses];

-- 12) Which city generated the highest revenue?
With Citypayments as (
	Select
		S.City,
		ISNULL(sum(P.amount),0) as Revenue
	from  Students S
	join Enrollments E
		on S.student_id = E.student_id
	left join Payments p
	 on e.enroll_id = p.enroll_id
	 Group by S.city
	 )
Select Top 1 * from Citypayments order by Revenue Desc;

-- 13) Average course fee per course. (Isn't this just the course price as everyone pays the same?)
Select course_name, avg(price) as [Average Fee] from Courses
	Group by course_name;

-- Actual average fee of courses, not grouped by course price
Select  avg(price) as [Average Fee] from Courses;


-- 14) Weekly enrollment trend (YYYY‑WW).
Select Concat(Datepart(Year,enroll_date), '-', DatePart(week,enroll_date)) as [Year and Month], count(enroll_id) as [Number enrolled] from Enrollments
Group by Datepart(Year,enroll_date), DatePart(week,enroll_date)
Order by Datepart(Year,enroll_date), DatePart(week,enroll_date);

-- 15) Payment mode split (% of total).
Select mode, (round(100*cast(count(*) as float)/sum(cast(count(*) as float)) Over(), 2)) as [Transactions %] from Payments
group by mode;


-- 16) Teacher gross margin (revenue − monthly salary).
WITH TeacherRevenue AS (
	Select
		T.teacher_id as [Teacher ID],
		T.teacher_name as [Teacher Name],
		ISNULL(sum(P.amount),0) as Revenue,
		ISNULL(T.monthly_salary,0) as [Monthly Salary]
		
	from  Teachers T
	left join ClassBatches CB
		ON T.teacher_id = CB.teacher_id
	left join Enrollments E 
		ON CB.batch_id = E.batch_id
	left join Payments P
		ON E.enroll_id = P.enroll_id
	Group by T.teacher_name,T.teacher_id, T.monthly_salary
	
) 
Select *, (Revenue - [Monthly Salary]) as [Gross Margin] from TeacherRevenue
Order By [Gross Margin] Desc;

-- 17) On‑time payment rate (≤14 days from enrollment).

With OnTime as (
	Select
	Case
		When DATEDIFF(day, E. enroll_date, P.payment_date) <= 14 THEN 'Yes'
		Else 'No'
	End As IsOnTime
	from Enrollments E
	join Payments P
		ON E.enroll_id = P.enroll_id
)
Select IsOnTime as [Was paid on time], (round(100*cast(Count(*) as float)/sum(cast(count(*) as float)) Over(), 2)) as [%] From OnTime
Group by IsOnTime;



-- 18) Average revenue per student (ARPU).
With StudentRev as (
	Select
		E.student_id as [ID],
		Sum(P.Amount) as Paid
	from Enrollments E
	join Payments P
		ON E.enroll_id = P.enroll_id
	Group by student_id
)
Select Round(Avg(Cast(Paid as float)), 2) as [Average Payment] from StudentRev;

-- 19) Active students in the latest month (attendance present=1).
Select Distinct(A.student_id) as ID, St.full_name as [Student Name] from Attendance A
Join Students St
	on A.student_id = St.student_id
Join Sessions Se
	on A.session_id = Se.session_id
where A.present = 1 AND month(Se.session_date) = (
Select Month(max(session_date)) From Sessions
);

-- 20) Next class date per batch after a given date.

Select batch_id as [Batch ID], min(session_date) as [Next session] from Sessions
where session_date > '2024-01-23'
group by batch_id;