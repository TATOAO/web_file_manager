
select userid, message_date
from message_table

left join (
    select userid, active_date
    from active_table_real
) as active_table
on message_table.user_id = active_table.userid and
    message_table.message_date = active_table.active_date



select message_table.userid, message_table.message_date, active_table.active_date
from message_table

left join (
    select userid, active_date
    from active_table_real
) as active_table
on message_table.userid = active_table.userid

where active_table.active_date >= message_table.message_date and
       active_table.active_date <= date_add(message_table.message_date, 3);





-- Create message_table
CREATE TABLE message_table (
    userid INT,
    message_date DATE
);

-- Insert sample data into message_table
INSERT INTO message_table (userid, message_date) VALUES
(1, '2021-01-01'),
(2, '2021-01-02'),
(3, '2021-01-03'),
(1, '2021-01-14'),
(2, '2021-01-05'),
(3, '2021-01-06');

-- Create active_table_real
CREATE TABLE active_table_real (
    userid INT,
    active_date DATE
);

-- Insert sample data into active_table_real
INSERT INTO active_table_real (userid, active_date) VALUES
(1, '2021-01-01'),
(3, '2021-01-02'),
(1, '2021-01-03'),
(3, '2021-01-07');
