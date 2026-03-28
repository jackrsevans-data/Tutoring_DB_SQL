/*

Schema (tables & key columns):

• Students(student_id PK, full_name, city, phone)

• Teachers(teacher_id PK, teacher_name, expertise, base_city, monthly_salary)

• Courses(course_id PK, course_name, duration_weeks, price)

• Batches(batch_id PK, course_id FK, teacher_id FK, start_date, days_per_week, time_slot)

• Enrollments(enroll_id PK, student_id FK, batch_id FK, enroll_date)

• Payments(payment_id PK, enroll_id FK, payment_date, amount, mode)

• Sessions(session_id PK, batch_id FK, session_date, topic)

• Attendance(session_id FK, student_id FK, present)

*/