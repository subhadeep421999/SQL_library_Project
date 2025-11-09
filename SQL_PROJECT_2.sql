create database project2;
use project2;
select * from books;

select * from branch;
select * from members;
select * from issued_status;
select * from return_status;
select * from employees;

-- Task 1. Create a New Book Record
-- "('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
insert into books (isbn,book_title,category,rental_price,status,author,publisher)
values ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');



-- Task 2: Update an Existing Member's Address
update members
set member_address = '125 Main St' 
where member_id= 'C101';

-- Task 3: Delete a Record from the Issued Status Table
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
delete from issued_status
where issued_id = 'IS116';


-- Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
select * from issued_status where issued_emp_id= 'E101';



-- Task 5: List Members Who Have Issued More Than One Book
-- Objective: Use GROUP BY to find members who have issued more than one book.
select issued_emp_id, count(issued_id) as no_of_issued_books  from issued_status
group by issued_emp_id having no_of_issued_books>1;


-- CTAS (Create Table As Select)
-- Task 6: Create Summary Tables**: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt 
create table book_cnts as
select b.isbn,b.book_title,count(i.issued_id) from books as b
inner join issued_status as i on b.isbn= i.issued_book_isbn
group by isbn,book_title;



-- Task 7. **Retrieve All Books in a Specific Category:
select * from books where category = 'classic';



-- Task 8: Find Total Rental Income by each Category:
select b.category, sum(b.rental_price) as total_rental_price, count(*) 
from books b inner join issued_status i on b.isbn= i.issued_book_isbn 
group by category;



-- Task 9. **List Members Who Registered in the Last 180 Days**:
select * from members where reg_date >= curdate() - interval 180 day;


-- Task 10: List Employees with Their Branch Manager's Name and their branch details**:
select e1.*,b.manager_id,e2.emp_name as manager_name from employees e1
inner join branch b on e1.branch_id = b.branch_id
inner join employees e2 on b.manager_id=e2.emp_id;



-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold 7 USD
create table NT as
select * from books where rental_price > 7;



-- Task 12: Retrieve the List of Books Not Yet Returned
select distinct ist.issued_book_name from issued_status as ist 
left join return_status as rs on ist.issued_id= rs.issued_id
where rs.return_id is null;


-- Adding new column in return_status
Alter table return_status
add column book_quality varchar(15) default 'Good';

update return_status
set book_quality = 'Damaged'
where issued_id in ('IS112', 'IS117', 'IS118');



-- Task 13: Identify Members with Overdue Books (assume a 30-day return period)
select ist.issued_member_id,m.member_name, bk.book_title, ist.issued_date,
datediff(current_date(), ist.issued_date) as over_dues_days
from issued_status as ist
inner join members as m
on m.member_id = ist.issued_member_id
inner join books as bk
on bk.isbn = ist.issued_book_isbn
left join return_status as rs
on rs.issued_id = ist.issued_id
where rs.return_date is null and datediff(current_date(), ist.issued_date) > 30
order by ist.issued_member_id;



-- Task 14: Update Book Status on Return. Write a query to update the status of books table to 'Yes' when they are returned ( based on entries in the return_status table)
Delimiter $$
create procedure add_return_records( in p_return_id varchar(10), in p_issued_id varchar(10), in p_book_quality varchar(15) )
begin declare v_isbn varchar(50);
declare v_book_name varchar(80); 

-- Insert return record
Insert into return_status (return_id, issued_id, return_date, book_quality)
values (p_return_id, p_issued_id, current_date(), p_book_quality);

-- Fetch book details from issued_status
select issued_book_isbn,issued_book_name into v_isbn, v_book_name
from issued_status where issued_id = p_issued_id;

-- Update book table
update books
set status = 'yes'
where isbn = v_isbn;

-- show message
select concat('Thank you for returning the book: ' v_book_name) as message;

end $$

Delimiter ;

-- calling function
call add_return_records('RS125', 'IS130','Good'); 



-- Task 15: Branch Performance Report. Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, 
-- and the total revenue generated from book rentals.
create table branch_report as
select b.branch_id, b.manager_id, count(ist.issued_id) as number_of_book_issued,
count(rs.return_id) as number_of_book_return, sum(bk.rental_price) as total_revenue
from issued_status ist inner join employees e on ist.issued_emp_id = e.emp_id
inner join branch b on e.branch_id = b.branch_id
left join  return_status rs on rs.issued_id = ist.issued_id
inner join books as bk on ist.issued_book_isbn = bk.isbn
group by b.branch_id, b.manager_id;  



 -- Task 16: CTAS: Create a table of active Members. Use the create table as (CTAS) statement to create a new table active members
 -- containing members who have issued at least one book in the last 6 months.
create table active_member as 
select * from members where member_id in
(select distinct issued_id from issued_status
where issued_date >= current_date - Interval 6 month);
 
select * from active_member;
 
 
 
 -- Task 17: Find the Employees with the Most Book Issues Processed
 -- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name ,number
 -- of books processed, and their branch.
select e.emp_name, b.branch_id, count(ist.issued_id) as number_of_issued_id from issued_status ist inner join employees e on e.emp_id = ist.issued_emp_id
inner join branch b on b.branch_id = e.branch_id
group by e.emp_name, b.branch_id  order by count(ist.issued_id) desc limit 3;
 


 -- Task 18: Identify Members Issuing High-Risk Books
 -- Write a query to Identify members who have issued books more than twice with the status 'damaged' in the books table. 
 -- Display the member name, book title and the number of times they have issued damaged books.
select m.member_name, b.book_title, count(*) as damaged_count from members m 
inner join issued_status ist on m.member_id = ist.issued_member_id
inner join books b on b.book_title = ist.issued_book_name
inner join return_status rs on ist.issued_id = rs.issued_id 
where rs.book_quality = 'damaged'
group by m.member_name, b.book_title 
having count(*) > 2;

 
 
 
 
 
 
 
 
 
 


