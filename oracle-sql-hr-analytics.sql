/* =====================================================================
   AZ: HR (Human Resources) bazası üzərində SQL tapşırıqları - şərhli versiya
   EN: SQL tasks on the HR (Human Resources) database - commented version
   ===================================================================== */


/* ---------------------------------------------------------------------
   TASK 1.c
   AZ: Hər bir təcrübəçi işə girdiyi tarixdən 6 ay sonra ilk maaşını alır.
       Əgər 6 ay sonrakı tarix ayın 1-dən fərqli günə düşərsə, maaş
       növbəti ayın 1-də verilir. Nəticədə soyad, maaş və ilk maaş
       alınan tarix (DD.MM.YYYY formatında) çıxarılır.
   EN: Each trainee receives their first salary 6 months after their
       hire date. If that date isn't the 1st of the month, the salary
       is paid on the 1st of the following month. Returns last name,
       salary, and first salary date (formatted as DD.MM.YYYY).
--------------------------------------------------------------------- */
select
     last_name,
     salary,
     hire_date,
     add_months(hire_date,6),                                          -- AZ: işə girmə tarixinə 6 ay əlavə edilir | EN: adds 6 months to hire date
     to_char(last_day(add_months(hire_date,6))+1,'dd.mm.yyyy')          -- AZ: həmin ayın son günü + 1 = növbəti ayın 1-i | EN: last day of that month + 1 = the 1st of the next month
from hr.employees;


/* ---------------------------------------------------------------------
   TASK 2
   AZ: Heç bir işçinin işləmədiyi şəhərlərin adlarını (duplikatsız) çıxarır.
   EN: Returns the names of cities where no employee works (without
       duplicates).
--------------------------------------------------------------------- */
select 
    distinct city                                                      -- AZ: təkrarlanan şəhər adlarını aradan qaldırır | EN: removes duplicate city names
from hr.locations l 
    left join hr.departments d on l.location_id = d.location_id        -- AZ: yerləşmə - şöbə əlaqəsi | EN: location-department link
    left join hr.employees e on d.department_id = e.department_id      -- AZ: şöbə - işçi əlaqəsi | EN: department-employee link
where employee_id is null;                                             -- AZ: heç bir işçisi olmayan şəhərlər | EN: cities with no matching employee


/* ---------------------------------------------------------------------
   TASK 3
   AZ: Hər bir işçinin öz ölkəsi üzrə neçənci işə girdiyini müəyyən edir.
   EN: Determines each employee's rank (order of hiring) within their
       own country.
--------------------------------------------------------------------- */
select
    first_name,
    hire_date,
    country_name,
    dense_rank() over (partition by country_name order by hire_date) as dr 
        -- AZ: ölkə üzrə bölünərək işə girmə tarixinə görə sıra nömrəsi
        -- EN: rank within each country ordered by hire date
from hr.employees e 
    left join hr.departments d on e.department_id = d.department_id
    left join hr.locations l on d.location_id = l.location_id
    left join hr.countries c on l.country_id = c.country_id;


/* ---------------------------------------------------------------------
   TASK 4
   AZ: Menecerinin maaşı özündən (işçidən) az olan işçiləri, işçinin və
       menecerinin adları ilə birlikdə çıxarır.
   EN: Returns employees whose manager earns less than they do, along
       with the employee's and manager's names.
--------------------------------------------------------------------- */
select
    e1.first_name,                                                     -- AZ: işçinin adı | EN: employee's name
    e1.salary,                                                         -- AZ: işçinin maaşı | EN: employee's salary
    e2.first_name,                                                     -- AZ: menecerin adı | EN: manager's name
    e2.salary                                                          -- AZ: menecerin maaşı | EN: manager's salary
from hr.employees e1 join hr.employees e2 on e1.manager_id = e2.employee_id  -- AZ: işçi - onun meneceri əlaqəsi (özünə qoşulma) | EN: employee-to-manager self join
    where e2.salary < e1.salary;                                       -- AZ: menecerin maaşı işçidən az olan hallar | EN: cases where manager's salary is lower than the employee's


/* ---------------------------------------------------------------------
   TASK 5
   AZ: Hər regionda yerləşən ölkələrin sayını çıxarır (region_id, count_country).
   EN: Returns the number of countries per region (region_id, count_country).
--------------------------------------------------------------------- */
select
    region_id,
    count(*) as count_country                                          -- AZ: region üzrə ölkə sayı | EN: number of countries per region
from hr.regions
group by region_id;


/* ---------------------------------------------------------------------
   TASK 6
   AZ: Hər bir işçinin salary üzrə azdan-çoxa sıralamada JOB_ID-si üzrə
       neçənci olduğunu göstərir.
   EN: Shows each employee's rank (ascending by salary) within their
       JOB_ID.
   NOT / NOTE: AZ: sorğuda ROW_NUMBER() PARTITION BY job_id ilə deyil,
   ümumi sıralama ilə yazılıb — orijinal koda toxunulmayıb.
   EN: the query uses ROW_NUMBER() without PARTITION BY job_id (global
   ranking) — left unchanged as in the original code.
--------------------------------------------------------------------- */
select 
    first_name,
    job_id,
    row_number() over (order by salary asc)                            -- AZ: maaşa görə artan sırada nömrələnmə | EN: numbering rows by ascending salary
from hr.employees;


/* ---------------------------------------------------------------------
   TASK 7
   AZ: Hər bir işçinin qarşısında, həmin işçinin o il işə girən neçənci
       işçi olduğunu göstərir.
   EN: Shows each employee's rank among those hired in the same year.
--------------------------------------------------------------------- */
select
    first_name,
    extract (year from hire_date) as hd,                               -- AZ: işə girmə ili | EN: hire year
    row_number() over (partition by extract (year from hire_date) order by hire_date) as rn 
        -- AZ: il üzrə bölünərək tarixə görə sıra nömrəsi
        -- EN: rank within each year ordered by hire date
from hr.employees;


/* ---------------------------------------------------------------------
   TASK 8
   AZ: Hər işçinin qarşısında, employee_id-yə görə sıralamada özündən
       2 əvvəl və 3 sonra gələn işçilərin maaşlarının cəmini göstərir.
   EN: For each employee, shows the sum of the salaries of the employee
       2 rows before and 3 rows after them (ordered by employee_id).
--------------------------------------------------------------------- */
select
    employee_id,
    salary,
    lag(salary,2,0) over(order by employee_id) + lead(salary,3,0) over(order by employee_id) 
        -- AZ: 2 sətr əvvəlki (LAG) və 3 sətr sonrakı (LEAD) maaşın cəmi, olmadıqda 0
        -- EN: sum of the salary 2 rows before (LAG) and 3 rows after (LEAD), defaulting to 0 if missing
from hr.employees;


/* ---------------------------------------------------------------------
   TASK 9
   AZ: Hər işçinin qarşısında, işlədiyi ölkədə işləyənlərdən ilk işə
       girən işçinin işə girmə tarixini göstərir (MIN() pəncərə funksiyası ilə).
   EN: For each employee, shows the earliest hire date among employees
       working in the same country (using the MIN() window function).
--------------------------------------------------------------------- */
select
    first_name,
    country_name,
    hire_date,
    min(hire_date) over(partition by country_name order by hire_date)  
        -- AZ: ölkə üzrə bölünərək ən erkən işə girmə tarixi
        -- EN: earliest hire date within each country
from hr.countries c 
left join hr.locations l on c.country_id = l.country_id
left join hr.departments d on l.location_id = d.location_id
left join hr.employees e on d.department_id = e.department_id;


/* ---------------------------------------------------------------------
   TASK 10
   AZ: Ən çox işçisi olan departamenti tapır.
   EN: Finds the department with the most employees.
--------------------------------------------------------------------- */
select department_name,
    count(*)                                                           -- AZ: departamentdəki işçi sayı | EN: number of employees in the department
from hr.employees e left join hr.departments d on e.department_id = d.department_id
group by department_name
order by count(*) desc fetch first 1 rows only;                        -- AZ: ən çox işçisi olan 1 departament | EN: the single department with the highest count


/* ---------------------------------------------------------------------
   TASK 11
   AZ: Şöbələr arası şahmat turniri - hər şöbənin hər əməkdaşı digər
       bütün şöbələrin bütün əməkdaşları ilə oynayır. Hər oyunun hər
       iki oyunçusunun adlarını qarşı-qarşıya çıxarır.
   EN: Inter-department chess tournament - every employee of a
       department plays every employee of every other department.
       Returns each pairing's two player names side by side.
--------------------------------------------------------------------- */
select
    e1.first_name || ' ' || e1.last_name as player_1,                  -- AZ: 1-ci oyunçunun tam adı | EN: full name of player 1
    e2.first_name || ' ' || e2.last_name as player_2,                  -- AZ: 2-ci oyunçunun tam adı | EN: full name of player 2
    e1.department_id,
    e2.department_id
from hr.employees e1 cross join hr.employees e2                        -- AZ: bütün mümkün kombinasiyalar üçün CROSS JOIN | EN: CROSS JOIN to generate every combination
where e1.department_id != e2.department_id                             -- AZ: yalnız fərqli şöbələrin işçiləri qarşılaşır | EN: only employees from different departments are paired
    and e1.employee_id <> e2.employee_id                                -- AZ: eyni işçinin özü ilə oynaması istisna olunur | EN: excludes an employee playing against themself
order by e1.department_id, e2.department_id;


/* ---------------------------------------------------------------------
   TASK 12
   AZ: İşçiləri maaşa görə çoxdan-aza sıralasaq, sondan əvvəlki (yəni
       2-ci ən yüksək) maaşı göstərir.
   EN: If employees are sorted by salary descending, returns the
       second-highest salary.
--------------------------------------------------------------------- */
select max(salary) from hr.employees where salary < (select max(salary) from hr.employees);
    -- AZ: ən yüksək maaşdan kiçik olan maaşların ən böyüyü = 2-ci ən yüksək maaş
    -- EN: the largest salary that is less than the overall max = the second-highest salary


/* ---------------------------------------------------------------------
   TASK 13
   AZ: Menecer olmayan (heç kimin meneceri olmayan) işçiləri çıxarır.
   EN: Returns employees who are not anyone's manager.
--------------------------------------------------------------------- */
select 
    first_name
from hr.employees 
where employee_id not in (select manager_id from hr.employees where manager_id is not null);
    -- AZ: manager_id sütununda heç yerdə görünməyən employee_id-lər
    -- EN: employee_ids that never appear as a manager_id


/* ---------------------------------------------------------------------
   TASK 14
   AZ: Orta maaşı ən kiçik olan departamentin adını və orta maaşını
       çıxarır (iki fərqli yanaşma ilə göstərilib).
   EN: Returns the department with the lowest average salary, along
       with that average (shown with two different approaches).
--------------------------------------------------------------------- */

-- AZ: 1-ci yanaşma: sıralayıb yalnız ilk sətri götürmək
-- EN: Approach 1: sort and take only the first row
select 
    department_name,
    avg(salary)
from hr.departments d left join hr.employees e on e.department_id = d.department_id
group by department_name
order by avg(salary) asc fetch first 1 rows only;

-- AZ: 2-ci yanaşma: alt sorğu ilə minimum orta maaşı tapıb ona bərabər olan sətri seçmək
-- EN: Approach 2: subquery finds the minimum average salary, then matches the row equal to it
select 
    department_name, 
    avg_salary 
from (select 
           d.department_name,
           avg(e.salary) as avg_salary
      from hr.departments d 
      left join hr.employees e on e.department_id = d.department_id
      group by d.department_name) 
      where avg_salary = (select min(avg_salary) from (select 
                                                          avg(e.salary) as avg_salary
                                                     from hr.departments d 
                                                     left join hr.employees e on e.department_id = d.department_id
                                                     group by d.department_name));


/* ---------------------------------------------------------------------
   TASK 15
   AZ: Employees cədvəlində 107 sətr var. Salary üzrə sıralamada tam
       ortaya düşən sətri çıxarır.
   EN: The Employees table has 107 rows. Returns the row that falls
       exactly in the middle when sorted by salary.
--------------------------------------------------------------------- */
select
    *
from (select 
          first_name,
          last_name,
          salary,
          row_number() over (order by salary) as rn from hr.employees)  -- AZ: maaşa görə sıra nömrəsi | EN: row number ordered by salary
where rn = (select 
                round(count(employee_id)/2) 
            from hr.employees);                                        -- AZ: ümumi sətir sayının yarısı (yuvarlaqlaşdırılmış) = orta sətir | EN: half of total row count (rounded) = the middle row


/* ---------------------------------------------------------------------
   TASK 16
   AZ: Hər departamentdə ilk işə qəbul olunan işçini (first_name,
       last_name, hire_date) çıxarır.
   EN: Returns the first-hired employee (first_name, last_name,
       hire_date) in each department.
--------------------------------------------------------------------- */
select
    first_name,
    last_name,
    hire_date
from (select
          first_name,
          last_name,
          hire_date,
          department_id,
          row_number() over (partition by department_id order by hire_date) as rn 
              -- AZ: departament üzrə bölünərək tarixə görə sıra nömrəsi
              -- EN: rank within each department ordered by hire date
      from hr.employees
    )
where rn = 1;                                                          -- AZ: hər departamentin ilk işçisi | EN: the first-hired employee in each department


/* ---------------------------------------------------------------------
   TASK 17
   AZ: Departamentin orta maaşı, o departamentdəki maksimal maaşın
       yarısından kiçik olan hallarda, o departamentdə işləyən
       əməkdaşları çıxarır.
   EN: Returns employees whose department's average salary is less
       than half of that department's maximum salary.
--------------------------------------------------------------------- */
select 
    * 
from
    (select 
         e.*,
         round(avg(e.salary) over(partition by e.department_id),1) as avg_salary,   -- AZ: departament üzrə orta maaş | EN: average salary per department
         max(e.salary) over(partition by e.department_id) as max_salary             -- AZ: departament üzrə maksimal maaş | EN: max salary per department
     from hr.employees e join hr.departments d on e.department_id = d.department_id)
     where avg_salary < max_salary/2;                                   -- AZ: orta maaş maksimal maaşın yarısından kiçikdirsə | EN: where average is less than half the max


/* ---------------------------------------------------------------------
   TASK 18
   AZ: İşçi sayı ən az olan ilk 3 departamentə uyğun işçilərin
       last_name və department_name-lərini çıxarır.
   EN: Returns last_name and department_name for employees belonging
       to the 3 departments with the fewest employees.
--------------------------------------------------------------------- */
select
    e.department_id,
    e.last_name,
    d.department_name
from hr.employees e 
join hr.departments d on e.department_id = d.department_id
where e.department_id in (select 
                            department_id
                        from ( select 
                                   department_id,
                                   count(employee_id)
                               from hr.employees 
                               group by department_id
                               order by count(employee_id) asc fetch first 3 rows only))  
                               -- AZ: işçi sayına görə artan sırada ilk 3 departament
                               -- EN: 3 departments with the fewest employees, ascending order
;


/* ---------------------------------------------------------------------
   TASK 19
   AZ: Hər il üzrə, həmin ildəki aylar üzrə işə girmə saylarının orta
       qiymətini çıxarır.
   EN: For each year, returns the average number of hires per month
       within that year.
--------------------------------------------------------------------- */
select 
    il,
    avg(employee_count) 
from (select
           extract (year from hire_date) as il,                        -- AZ: işə girmə ili | EN: hire year
           count(hire_date) as employee_count                          -- AZ: həmin il üzrə işə girənlərin sayı | EN: number of hires in that year
      from hr.employees
      group by extract (year from hire_date))
group by il;
