
-- =========================
-- 一、建库与选库
-- =========================
drop database if exists pet;
create database pet default character set utf8mb4 collate utf8mb4_0900_ai_ci;
use pet;

-- =========================
-- 二、建表
-- =========================
create table owner_table (
	owner_id int auto_increment primary key comment '主人id',
	owner_birthday date comment '主人生日',
	owner_address varchar(50) comment '地址',
	owner_nickname varchar(30) not null comment '昵称',
	owner_sex char(1) check (owner_sex in ('男','女')) comment '性别',
	owner_phone char(11) not null unique check (char_length(owner_phone)=11) comment '联系方式',
	created_at datetime not null default current_timestamp comment '创建时间',
	updated_at datetime not null default current_timestamp on update current_timestamp comment '更新时间',
	owner_password  VARCHAR(30) NOT NULL check(
			LENGTH(owner_password) >= 8
			AND owner_password REGEXP '[A-Z]'
			AND owner_password REGEXP '[a-z]'
			AND owner_password REGEXP '[0-9]'
	) comment'账号密码'
) comment='主人表';

create table food_manu(
	food_manu_id int auto_increment primary key comment '食物厂商标号',
	food_manu_phone char(11) unique check(char_length(food_manu_phone)=11) comment '食物厂商电话',
	food_manu_addr varchar(30) comment '食物厂商地址'
) comment='食物厂商表';

create table food(
	food_id int auto_increment primary key comment '食物编号',
	food_category char(1) not null check(food_category in('猫','狗')) comment '食物是谁吃的',
	food_name varchar(30) not null comment '食物名称',
	food_manu_id int comment '食物厂商编号',
	constraint fk_food_and_manu foreign key(food_manu_id) references food_manu(food_manu_id) on delete set null on update cascade
) comment='食物表';

create table food_store (
	food_id int not null comment '食物编号',
	owner_id int not null comment '主人编号',
	food_store_batch_no int not null comment '食物存储批次号',
	food_store_expire_time date not null comment '食物过期时间',
	food_store_remaining_amount int check(food_store_remaining_amount >= 0) comment '食物剩余量',
	primary key (owner_id, food_id, food_store_batch_no),
	constraint fk_food_store_owner foreign key (owner_id) references owner_table(owner_id) on delete restrict on update cascade,
	constraint fk_food_store_food foreign key (food_id) references food(food_id) on delete restrict on update cascade
) comment='食物存储表';

create table medicine_manu(
	medicine_manu_id int auto_increment primary key comment '药物厂商标号',
	medicine_manu_phone char(11) unique check(char_length(medicine_manu_phone)=11) comment '药物厂商电话',
	medicine_manu_addr varchar(30) comment '药物厂商地址'
) comment='药物厂商表';

create table medicine(
	medicine_id int auto_increment primary key comment '药物编号',
	medicine_name varchar(30) not null comment '药物名称',
	medicine_instruction varchar(255) comment '使用说明',
	medicine_manu_id int comment '药物厂商编号',
	medicine_category char(1) not null check (medicine_category in ('猫', '狗')) comment '药物适用动物',
	constraint fk_medicine_and_manu foreign key(medicine_manu_id) references medicine_manu(medicine_manu_id) on delete set null on update cascade
) comment='药物表';

create table medicine_store(
	medicine_id int not null comment '药物编号',
	owner_id int not null comment '主人编号',
	medicine_batch_no int not null comment '药物存储批次号',
	medicine_store_expire_time date not null comment '药物过期时间',
	medicine_store_remaining_amount int check(medicine_store_remaining_amount >= 0) comment '药物剩余量',
	primary key(owner_id, medicine_id, medicine_batch_no),
	constraint fk_medicine_store_owner foreign key(owner_id) references owner_table(owner_id) on delete restrict on update cascade,
	constraint fk_medicine_store_med foreign key(medicine_id) references medicine(medicine_id) on delete restrict on update cascade
) comment='药物存储表';

create table pet(
	pet_id int auto_increment primary key comment '宠物编号',
	owner_id int not null comment '主人编号',
	pet_sex char(1) check (pet_sex in ('男','女')) comment '宠物性别',
	pet_name varchar(20) not null comment '宠物名字',
	pet_birthday date not null comment '宠物出生日期',
	pet_category char(1) not null check (pet_category in ('猫','狗')) comment '宠物种类',
	created_at datetime not null default current_timestamp comment '创建时间',
	updated_at datetime not null default current_timestamp on update current_timestamp comment '更新时间',
	constraint fk_pet_owner foreign key(owner_id) references owner_table(owner_id) on delete restrict on update cascade
) comment='宠物表';

create table medicine_plan(
	plan_id int auto_increment primary key comment '喂药计划编号',
	medicine_id int not null comment '药物编号',
	medicine_feed_amount int not null check(medicine_feed_amount > 0) comment '喂食量',
	medicine_feed_time datetime not null comment '喂药时间',
	pet_id int not null comment '宠物编号',
	constraint fk_plan_and_medicine foreign key(medicine_id) references medicine(medicine_id) on delete restrict on update cascade,
	constraint fk_plan_pet foreign key(pet_id) references pet(pet_id) on delete restrict on update cascade
) comment='药物计划表';

create table cat(
	pet_id int primary key comment '宠物编号',
	cat_claw_cycle int check(cat_claw_cycle > 0) comment '剪爪周期',
	cat_litter varchar(30) comment '常用猫砂',
	constraint fk_cat_pet foreign key(pet_id) references pet(pet_id) on delete cascade on update cascade
) comment='猫表';

create table dog(
	pet_id int primary key comment '宠物编号',
	dog_walk_level varchar(20) comment '遛狗需求等级',
	dog_license_no varchar(30) unique comment '犬证号',
	constraint fk_dog_pet foreign key(pet_id) references pet(pet_id) on delete cascade on update cascade
) comment='狗表';

-- =========================
-- 三、初始化数据
-- =========================
insert into owner_table(owner_id, owner_birthday, owner_address, owner_nickname, owner_sex, owner_phone,owner_password) values
(1, '1999-03-12', '天津市南开区', '阿青', '女', '13800000001','Aa123456'),
(2, '1998-07-21', '北京市海淀区', '老周', '男', '13800000002','Bb123456'),
(3, '2000-11-05', '上海市浦东新区', '小林', '女', '13800000003','Cc123456');

insert into food_manu(food_manu_id, food_manu_phone, food_manu_addr) values
(1, '13900000001', '天津市西青区'),
(2, '13900000002', '北京市朝阳区'),
(3, '13900000003', '上海市闵行区');

insert into food(food_id, food_category, food_name, food_manu_id) values
(1, '猫', '幼猫粮', 1),
(2, '猫', '成猫罐头', 2),
(3, '狗', '成犬粮', 1),
(4, '狗', '狗狗零食棒', 3);

insert into medicine_manu(medicine_manu_id, medicine_manu_phone, medicine_manu_addr) values
(1, '13700000001', '广州市天河区'),
(2, '13700000002', '深圳市南山区'),
(3, '13700000003', '杭州市西湖区');

insert into medicine(medicine_id, medicine_name, medicine_instruction, medicine_manu_id, medicine_category) values
(1, '猫咪驱虫片', '每月一次，饭后服用', 1, '猫'),
(2, '猫咪益生菌', '肠胃不适时每日一次', 2, '猫'),
(3, '狗狗驱虫片', '每月一次，按体重服用', 1, '狗'),
(4, '狗狗消炎药', '每日两次，连续服用三天', 3, '狗');

insert into pet(pet_id, owner_id, pet_sex, pet_name, pet_birthday, pet_category) values
(1, 1, '女', '奶糖', '2023-05-01', '猫'),
(2, 1, '男', '雪球', '2022-08-15', '猫'),
(3, 2, '男', '旺财', '2021-10-10', '狗'),
(4, 3, '女', '可可', '2024-01-20', '狗');

insert into cat(pet_id, cat_claw_cycle, cat_litter) values
(1, 14, '豆腐猫砂'),
(2, 10, '膨润土猫砂');

insert into dog(pet_id, dog_walk_level, dog_license_no) values
(3, '高', 'DOG2026001'),
(4, '中', 'DOG2026002');

insert into food_store(food_id, owner_id, food_store_batch_no, food_store_expire_time, food_store_remaining_amount) values
(1, 1, 1001, '2026-12-31', 5),
(1, 1, 1002, '2025-12-31', 1),
(2, 1, 1003, '2026-08-15', 8),
(3, 2, 2001, '2026-10-01', 12),
(4, 2, 2002, '2025-05-01', 2),
(3, 3, 3001, '2026-11-20', 6);

insert into medicine_store(medicine_id, owner_id, medicine_batch_no, medicine_store_expire_time, medicine_store_remaining_amount) values
(1, 1, 5001, '2026-09-30', 10),
(2, 1, 5002, '2026-07-15', 6),
(1, 1, 5003, '2026-06-10', 10),
(3, 2, 6001, '2026-12-01', 9),
(4, 2, 6002, '2025-04-01', 3),
(3, 3, 7001, '2026-10-20', 5);

insert into medicine_plan(plan_id, medicine_id, medicine_feed_amount, medicine_feed_time, pet_id) values
(1, 1, 1, '2026-06-05 08:00:00', 1),
(2, 2, 2, '2026-06-05 20:00:00', 2),
(3, 3, 1, '2026-06-05 09:00:00', 3),
(4, 4, 2, '2026-06-05 21:00:00', 4);

-- =========================
-- 四、业务约束触发器
-- =========================
use pet;

delimiter $$

drop trigger if exists trigger_medicine_plan_check_insert$$
create trigger trigger_medicine_plan_check_insert
before insert on medicine_plan
for each row
begin
	declare v_pet_category char(1);
	declare v_medicine_category char(1);

	select pet_category into v_pet_category
	from pet
	where pet_id = new.pet_id;

	select medicine_category into v_medicine_category
	from medicine
	where medicine_id = new.medicine_id;

	if v_pet_category is null then
		signal sqlstate '45000'
		set message_text = '对应宠物不存在，不能添加喂药计划';
	end if;

	if v_medicine_category is null then
		signal sqlstate '45000'
		set message_text = '对应药物不存在，不能添加喂药计划';
	end if;

	if v_pet_category <> v_medicine_category then
		signal sqlstate '45000'
		set message_text = '药物适用动物与宠物种类不匹配，不能添加喂药计划';
	end if;
end$$

drop trigger if exists trigger_medicine_plan_check_update$$
create trigger trigger_medicine_plan_check_update
before update on medicine_plan
for each row
begin
	declare v_pet_category char(1);
	declare v_medicine_category char(1);

	select pet_category into v_pet_category
	from pet
	where pet_id = new.pet_id;

	select medicine_category into v_medicine_category
	from medicine
	where medicine_id = new.medicine_id;

	if v_pet_category is null then
		signal sqlstate '45000'
		set message_text = '对应宠物不存在，不能修改喂药计划';
	end if;

	if v_medicine_category is null then
		signal sqlstate '45000'
		set message_text = '对应药物不存在，不能修改喂药计划';
	end if;

	if v_pet_category <> v_medicine_category then
		signal sqlstate '45000'
		set message_text = '药物适用动物与宠物种类不匹配，不能修改喂药计划';
	end if;
end$$

drop trigger if exists trigger_cat_check_insert$$
create trigger trigger_cat_check_insert
before insert on cat
for each row
begin
	declare v_pet_category char(1);

	select pet_category into v_pet_category
	from pet
	where pet_id = new.pet_id;

	if v_pet_category is null then
		signal sqlstate '45000'
		set message_text = '对应宠物不存在，不能插入 cat 表';
	end if;

	if v_pet_category <> '猫' then
		signal sqlstate '45000'
		set message_text = '只有猫类宠物才能插入 cat 表';
	end if;
end$$

drop trigger if exists trigger_cat_check_update$$
create trigger trigger_cat_check_update
before update on cat
for each row
begin
	declare v_pet_category char(1);

	select pet_category into v_pet_category
	from pet
	where pet_id = new.pet_id;

	if v_pet_category is null then
		signal sqlstate '45000'
		set message_text = '对应宠物不存在，不能修改 cat 表';
	end if;

	if v_pet_category <> '猫' then
		signal sqlstate '45000'
		set message_text = '只有猫类宠物才能保留在 cat 表';
	end if;
end$$

drop trigger if exists trigger_dog_check_insert$$
create trigger trigger_dog_check_insert
before insert on dog
for each row
begin
	declare v_pet_category char(1);

	select pet_category into v_pet_category
	from pet
	where pet_id = new.pet_id;

	if v_pet_category is null then
		signal sqlstate '45000'
		set message_text = '对应宠物不存在，不能插入 dog 表';
	end if;

	if v_pet_category <> '狗' then
		signal sqlstate '45000'
		set message_text = '只有狗类宠物才能插入 dog 表';
	end if;
end$$

drop trigger if exists trigger_dog_check_update$$
create trigger trigger_dog_check_update
before update on dog
for each row
begin
	declare v_pet_category char(1);

	select pet_category into v_pet_category
	from pet
	where pet_id = new.pet_id;

	if v_pet_category is null then
		signal sqlstate '45000'
		set message_text = '对应宠物不存在，不能修改 dog 表';
	end if;

	if v_pet_category <> '狗' then
		signal sqlstate '45000'
		set message_text = '只有狗类宠物才能保留在 dog 表';
	end if;
end$$

delimiter ;

-- =========================
-- 五、事务存储过程
-- =========================

delimiter $$

drop procedure if exists proc_execute_medicine_plan$$
create procedure proc_execute_medicine_plan(
	in p_plan_id int,
	in p_owner_id int,
	in p_medicine_batch_no int
)
begin
	declare v_medicine_id int;
	declare v_feed_amount int;
	declare v_remaining_amount int;

	declare exit handler for sqlexception
	begin
		rollback;
		resignal;
	end;

	start transaction;

	select mp.medicine_id, mp.medicine_feed_amount
	into v_medicine_id, v_feed_amount
	from medicine_plan mp
	join pet p on mp.pet_id = p.pet_id
	where mp.plan_id = p_plan_id
	  and p.owner_id = p_owner_id
	limit 1;

	if v_medicine_id is null then
		signal sqlstate '45000'
		set message_text = '未找到该主人的喂药计划';
	end if;

	if v_feed_amount <= 0 then
		signal sqlstate '45000'
		set message_text = '喂药量非法';
	end if;

	select medicine_store_remaining_amount
	into v_remaining_amount
	from medicine_store
	where owner_id = p_owner_id
	  and medicine_id = v_medicine_id
	  and medicine_batch_no = p_medicine_batch_no
	for update;

	if v_remaining_amount is null then
		signal sqlstate '45000'
		set message_text = '未找到对应药物库存批次';
	end if;

	if v_remaining_amount < v_feed_amount then
		signal sqlstate '45000'
		set message_text = '药物库存不足，无法执行喂药计划';
	end if;

	update medicine_store
	set medicine_store_remaining_amount = medicine_store_remaining_amount - v_feed_amount
	where owner_id = p_owner_id
	  and medicine_id = v_medicine_id
	  and medicine_batch_no = p_medicine_batch_no;

	commit;
end$$

delimiter ;

-- =========================
-- 六、视图
-- =========================
use pet;

DROP VIEW IF EXISTS v_pet_medicine_plan_detail;
DROP VIEW IF EXISTS v_medicine_store_detail;
DROP VIEW IF EXISTS v_food_store_detail;
DROP VIEW IF EXISTS v_owner_pet_detail;

CREATE VIEW v_owner_pet_detail AS
SELECT
    o.owner_id,
    o.owner_nickname,
    o.owner_phone,
    o.owner_address,
    p.pet_id,
    p.pet_name,
    p.pet_category,
    p.pet_sex,
    p.pet_birthday,
    c.cat_claw_cycle,
    c.cat_litter,
    d.dog_walk_level,
    d.dog_license_no
FROM owner_table o
JOIN pet p
    ON o.owner_id = p.owner_id
LEFT JOIN cat c
    ON p.pet_id = c.pet_id
LEFT JOIN dog d
    ON p.pet_id = d.pet_id;

CREATE VIEW v_food_store_detail AS
SELECT
    fs.owner_id,
    o.owner_nickname,
    fs.food_id,
    f.food_name,
    f.food_category,
    fm.food_manu_id,
    fm.food_manu_addr,
    fm.food_manu_phone,
    fs.food_store_batch_no,
    fs.food_store_expire_time,
    fs.food_store_remaining_amount
FROM food_store fs
JOIN owner_table o
    ON fs.owner_id = o.owner_id
JOIN food f
    ON fs.food_id = f.food_id
LEFT JOIN food_manu fm
    ON f.food_manu_id = fm.food_manu_id;

CREATE VIEW v_medicine_store_detail AS
SELECT
    ms.owner_id,
    o.owner_nickname,
    ms.medicine_id,
    m.medicine_name,
    m.medicine_category,
    m.medicine_instruction,
    mm.medicine_manu_id,
    mm.medicine_manu_addr,
    mm.medicine_manu_phone,
    ms.medicine_batch_no,
    ms.medicine_store_expire_time,
    ms.medicine_store_remaining_amount
FROM medicine_store ms
JOIN owner_table o
    ON ms.owner_id = o.owner_id
JOIN medicine m
    ON ms.medicine_id = m.medicine_id
LEFT JOIN medicine_manu mm
    ON m.medicine_manu_id = mm.medicine_manu_id;

CREATE VIEW v_pet_medicine_plan_detail AS
SELECT
    mp.plan_id,
    o.owner_id,
    o.owner_nickname,
    o.owner_phone,
    p.pet_id,
    p.pet_name,
    p.pet_category,
    p.pet_sex,
    m.medicine_id,
    m.medicine_name,
    m.medicine_category,
    m.medicine_instruction,
    mp.medicine_feed_time,
    mp.medicine_feed_amount,
    stock.total_remaining_amount,
    stock.nearest_expire_date
FROM medicine_plan mp
JOIN pet p
    ON mp.pet_id = p.pet_id
JOIN owner_table o
    ON p.owner_id = o.owner_id
JOIN medicine m
    ON mp.medicine_id = m.medicine_id
LEFT JOIN (
    SELECT
        owner_id,
        medicine_id,
        SUM(medicine_store_remaining_amount) AS total_remaining_amount,
        MIN(medicine_store_expire_time) AS nearest_expire_date
    FROM medicine_store
    GROUP BY owner_id, medicine_id
) stock
    ON stock.owner_id = o.owner_id
   AND stock.medicine_id = m.medicine_id;

-- =========================
-- 七、示例查询
-- =========================
SELECT *
FROM v_owner_pet_detail
WHERE owner_id = 1;

SELECT *
FROM v_food_store_detail
WHERE owner_id = 1;

SELECT *
FROM v_food_store_detail
WHERE food_store_expire_time < CURRENT_DATE;

SELECT *
FROM v_food_store_detail
WHERE food_store_expire_time <= '2026-12-31';

SELECT *
FROM v_medicine_store_detail
WHERE owner_id = 1;

SELECT *
FROM v_medicine_store_detail
WHERE medicine_store_expire_time < CURRENT_DATE;

SELECT *
FROM v_medicine_store_detail
WHERE medicine_store_expire_time <= '2026-12-31';

SELECT *
FROM v_pet_medicine_plan_detail
WHERE pet_id = 1;

SELECT *
FROM v_pet_medicine_plan_detail
WHERE owner_id = 1;

SELECT *
FROM v_pet_medicine_plan_detail
WHERE medicine_feed_time <= '2026-06-30 23:59:59';

SELECT *
FROM v_pet_medicine_plan_detail
WHERE total_remaining_amount IS NULL
   OR total_remaining_amount < medicine_feed_amount;

use pet;

-- =========================
-- 八、操作日志
-- =========================
drop table if exists operation_log;
create table operation_log (
    log_id bigint auto_increment primary key comment '日志编号',
    app_user_id int null comment '业务用户id',
    db_user varchar(100) not null comment '数据库账号',
    action_type varchar(10) not null comment '操作类型：SELECT/INSERT/UPDATE/DELETE',
    table_name varchar(50) not null comment '操作对象',
    record_key varchar(100) comment '记录主键标识',
    old_data json comment '旧数据快照',
    new_data json comment '新数据快照',
    action_note varchar(255) comment '操作说明',
    action_time datetime not null default current_timestamp comment '操作时间',
    index idx_operation_log_time(action_time),
    index idx_operation_log_user(app_user_id),
    index idx_operation_log_table(table_name, action_type)
) comment='后端操作日志表';

delimiter $$

drop procedure if exists proc_write_operation_log$$
create procedure proc_write_operation_log(
    in p_action_type varchar(10),
    in p_table_name varchar(50),
    in p_record_key varchar(100),
    in p_old_data json,
    in p_new_data json,
    in p_action_note varchar(255)
)
begin
    insert into operation_log(
        app_user_id,
        db_user,
        action_type,
        table_name,
        record_key,
        old_data,
        new_data,
        action_note
    )
    values (
        @app_user_id,
        current_user(),
        p_action_type,
        p_table_name,
        p_record_key,
        p_old_data,
        p_new_data,
        coalesce(p_action_note, @app_action_note)
    );
end$$

drop procedure if exists proc_write_select_log$$
create procedure proc_write_select_log(
    in p_target_name varchar(50),
    in p_query_name varchar(100),
    in p_query_params json
)
begin
    call proc_write_operation_log(
        'SELECT',
        p_target_name,
        null,
        null,
        p_query_params,
        p_query_name
    );
end$$

drop trigger if exists trg_owner_table_log_insert$$
drop trigger if exists trg_owner_table_log_update$$
drop trigger if exists trg_owner_table_log_delete$$

drop trigger if exists trg_pet_log_insert$$
drop trigger if exists trg_pet_log_update$$
drop trigger if exists trg_pet_log_delete$$

drop trigger if exists trg_cat_log_insert$$
drop trigger if exists trg_cat_log_update$$
drop trigger if exists trg_cat_log_delete$$

drop trigger if exists trg_dog_log_insert$$
drop trigger if exists trg_dog_log_update$$
drop trigger if exists trg_dog_log_delete$$

drop trigger if exists trg_food_store_log_insert$$
drop trigger if exists trg_food_store_log_update$$
drop trigger if exists trg_food_store_log_delete$$

drop trigger if exists trg_medicine_store_log_insert$$
drop trigger if exists trg_medicine_store_log_update$$
drop trigger if exists trg_medicine_store_log_delete$$

drop trigger if exists trg_medicine_plan_log_insert$$
drop trigger if exists trg_medicine_plan_log_update$$
drop trigger if exists trg_medicine_plan_log_delete$$

create trigger trg_owner_table_log_insert
after insert on owner_table
for each row
begin
    call proc_write_operation_log(
        'INSERT',
        'owner_table',
        concat('owner_id=', new.owner_id),
        null,
        json_object(
            'owner_id', new.owner_id,
            'owner_nickname', new.owner_nickname,
            'owner_phone', new.owner_phone,
            'owner_address', new.owner_address,
            'owner_birthday', new.owner_birthday,
            'owner_sex', new.owner_sex
        ),
        '新增主人'
    );
end$$

create trigger trg_owner_table_log_update
after update on owner_table
for each row
begin
    call proc_write_operation_log(
        'UPDATE',
        'owner_table',
        concat('owner_id=', new.owner_id),
        json_object(
            'owner_id', old.owner_id,
            'owner_nickname', old.owner_nickname,
            'owner_phone', old.owner_phone,
            'owner_address', old.owner_address,
            'owner_birthday', old.owner_birthday,
            'owner_sex', old.owner_sex
        ),
        json_object(
            'owner_id', new.owner_id,
            'owner_nickname', new.owner_nickname,
            'owner_phone', new.owner_phone,
            'owner_address', new.owner_address,
            'owner_birthday', new.owner_birthday,
            'owner_sex', new.owner_sex
        ),
        '修改主人'
    );
end$$

create trigger trg_owner_table_log_delete
after delete on owner_table
for each row
begin
    call proc_write_operation_log(
        'DELETE',
        'owner_table',
        concat('owner_id=', old.owner_id),
        json_object(
            'owner_id', old.owner_id,
            'owner_nickname', old.owner_nickname,
            'owner_phone', old.owner_phone,
            'owner_address', old.owner_address,
            'owner_birthday', old.owner_birthday,
            'owner_sex', old.owner_sex
        ),
        null,
        '删除主人'
    );
end$$

create trigger trg_pet_log_insert
after insert on pet
for each row
begin
    call proc_write_operation_log(
        'INSERT',
        'pet',
        concat('pet_id=', new.pet_id),
        null,
        json_object(
            'pet_id', new.pet_id,
            'owner_id', new.owner_id,
            'pet_name', new.pet_name,
            'pet_category', new.pet_category,
            'pet_sex', new.pet_sex,
            'pet_birthday', new.pet_birthday
        ),
        '新增宠物'
    );
end$$

create trigger trg_pet_log_update
after update on pet
for each row
begin
    call proc_write_operation_log(
        'UPDATE',
        'pet',
        concat('pet_id=', new.pet_id),
        json_object(
            'pet_id', old.pet_id,
            'owner_id', old.owner_id,
            'pet_name', old.pet_name,
            'pet_category', old.pet_category,
            'pet_sex', old.pet_sex,
            'pet_birthday', old.pet_birthday
        ),
        json_object(
            'pet_id', new.pet_id,
            'owner_id', new.owner_id,
            'pet_name', new.pet_name,
            'pet_category', new.pet_category,
            'pet_sex', new.pet_sex,
            'pet_birthday', new.pet_birthday
        ),
        '修改宠物'
    );
end$$

create trigger trg_pet_log_delete
after delete on pet
for each row
begin
    call proc_write_operation_log(
        'DELETE',
        'pet',
        concat('pet_id=', old.pet_id),
        json_object(
            'pet_id', old.pet_id,
            'owner_id', old.owner_id,
            'pet_name', old.pet_name,
            'pet_category', old.pet_category,
            'pet_sex', old.pet_sex,
            'pet_birthday', old.pet_birthday
        ),
        null,
        '删除宠物'
    );
end$$

create trigger trg_cat_log_insert
after insert on cat
for each row
begin
    call proc_write_operation_log(
        'INSERT',
        'cat',
        concat('pet_id=', new.pet_id),
        null,
        json_object(
            'pet_id', new.pet_id,
            'cat_claw_cycle', new.cat_claw_cycle,
            'cat_litter', new.cat_litter
        ),
        '新增猫子类信息'
    );
end$$

create trigger trg_cat_log_update
after update on cat
for each row
begin
    call proc_write_operation_log(
        'UPDATE',
        'cat',
        concat('pet_id=', new.pet_id),
        json_object(
            'pet_id', old.pet_id,
            'cat_claw_cycle', old.cat_claw_cycle,
            'cat_litter', old.cat_litter
        ),
        json_object(
            'pet_id', new.pet_id,
            'cat_claw_cycle', new.cat_claw_cycle,
            'cat_litter', new.cat_litter
        ),
        '修改猫子类信息'
    );
end$$

create trigger trg_cat_log_delete
after delete on cat
for each row
begin
    call proc_write_operation_log(
        'DELETE',
        'cat',
        concat('pet_id=', old.pet_id),
        json_object(
            'pet_id', old.pet_id,
            'cat_claw_cycle', old.cat_claw_cycle,
            'cat_litter', old.cat_litter
        ),
        null,
        '删除猫子类信息'
    );
end$$

create trigger trg_dog_log_insert
after insert on dog
for each row
begin
    call proc_write_operation_log(
        'INSERT',
        'dog',
        concat('pet_id=', new.pet_id),
        null,
        json_object(
            'pet_id', new.pet_id,
            'dog_walk_level', new.dog_walk_level,
            'dog_license_no', new.dog_license_no
        ),
        '新增狗子类信息'
    );
end$$

create trigger trg_dog_log_update
after update on dog
for each row
begin
    call proc_write_operation_log(
        'UPDATE',
        'dog',
        concat('pet_id=', new.pet_id),
        json_object(
            'pet_id', old.pet_id,
            'dog_walk_level', old.dog_walk_level,
            'dog_license_no', old.dog_license_no
        ),
        json_object(
            'pet_id', new.pet_id,
            'dog_walk_level', new.dog_walk_level,
            'dog_license_no', new.dog_license_no
        ),
        '修改狗子类信息'
    );
end$$

create trigger trg_dog_log_delete
after delete on dog
for each row
begin
    call proc_write_operation_log(
        'DELETE',
        'dog',
        concat('pet_id=', old.pet_id),
        json_object(
            'pet_id', old.pet_id,
            'dog_walk_level', old.dog_walk_level,
            'dog_license_no', old.dog_license_no
        ),
        null,
        '删除狗子类信息'
    );
end$$

create trigger trg_food_store_log_insert
after insert on food_store
for each row
begin
    call proc_write_operation_log(
        'INSERT',
        'food_store',
        concat('owner_id=', new.owner_id, ',food_id=', new.food_id, ',batch_no=', new.food_store_batch_no),
        null,
        json_object(
            'owner_id', new.owner_id,
            'food_id', new.food_id,
            'food_store_batch_no', new.food_store_batch_no,
            'food_store_expire_time', new.food_store_expire_time,
            'food_store_remaining_amount', new.food_store_remaining_amount
        ),
        '新增食品库存'
    );
end$$

create trigger trg_food_store_log_update
after update on food_store
for each row
begin
    call proc_write_operation_log(
        'UPDATE',
        'food_store',
        concat('owner_id=', new.owner_id, ',food_id=', new.food_id, ',batch_no=', new.food_store_batch_no),
        json_object(
            'owner_id', old.owner_id,
            'food_id', old.food_id,
            'food_store_batch_no', old.food_store_batch_no,
            'food_store_expire_time', old.food_store_expire_time,
            'food_store_remaining_amount', old.food_store_remaining_amount
        ),
        json_object(
            'owner_id', new.owner_id,
            'food_id', new.food_id,
            'food_store_batch_no', new.food_store_batch_no,
            'food_store_expire_time', new.food_store_expire_time,
            'food_store_remaining_amount', new.food_store_remaining_amount
        ),
        '修改食品库存'
    );
end$$

create trigger trg_food_store_log_delete
after delete on food_store
for each row
begin
    call proc_write_operation_log(
        'DELETE',
        'food_store',
        concat('owner_id=', old.owner_id, ',food_id=', old.food_id, ',batch_no=', old.food_store_batch_no),
        json_object(
            'owner_id', old.owner_id,
            'food_id', old.food_id,
            'food_store_batch_no', old.food_store_batch_no,
            'food_store_expire_time', old.food_store_expire_time,
            'food_store_remaining_amount', old.food_store_remaining_amount
        ),
        null,
        '删除食品库存'
    );
end$$

create trigger trg_medicine_store_log_insert
after insert on medicine_store
for each row
begin
    call proc_write_operation_log(
        'INSERT',
        'medicine_store',
        concat('owner_id=', new.owner_id, ',medicine_id=', new.medicine_id, ',batch_no=', new.medicine_batch_no),
        null,
        json_object(
            'owner_id', new.owner_id,
            'medicine_id', new.medicine_id,
            'medicine_batch_no', new.medicine_batch_no,
            'medicine_store_expire_time', new.medicine_store_expire_time,
            'medicine_store_remaining_amount', new.medicine_store_remaining_amount
        ),
        '新增药物库存'
    );
end$$

create trigger trg_medicine_store_log_update
after update on medicine_store
for each row
begin
    call proc_write_operation_log(
        'UPDATE',
        'medicine_store',
        concat('owner_id=', new.owner_id, ',medicine_id=', new.medicine_id, ',batch_no=', new.medicine_batch_no),
        json_object(
            'owner_id', old.owner_id,
            'medicine_id', old.medicine_id,
            'medicine_batch_no', old.medicine_batch_no,
            'medicine_store_expire_time', old.medicine_store_expire_time,
            'medicine_store_remaining_amount', old.medicine_store_remaining_amount
        ),
        json_object(
            'owner_id', new.owner_id,
            'medicine_id', new.medicine_id,
            'medicine_batch_no', new.medicine_batch_no,
            'medicine_store_expire_time', new.medicine_store_expire_time,
            'medicine_store_remaining_amount', new.medicine_store_remaining_amount
        ),
        '修改药物库存'
    );
end$$

create trigger trg_medicine_store_log_delete
after delete on medicine_store
for each row
begin
    call proc_write_operation_log(
        'DELETE',
        'medicine_store',
        concat('owner_id=', old.owner_id, ',medicine_id=', old.medicine_id, ',batch_no=', old.medicine_batch_no),
        json_object(
            'owner_id', old.owner_id,
            'medicine_id', old.medicine_id,
            'medicine_batch_no', old.medicine_batch_no,
            'medicine_store_expire_time', old.medicine_store_expire_time,
            'medicine_store_remaining_amount', old.medicine_store_remaining_amount
        ),
        null,
        '删除药物库存'
    );
end$$

create trigger trg_medicine_plan_log_insert
after insert on medicine_plan
for each row
begin
    call proc_write_operation_log(
        'INSERT',
        'medicine_plan',
        concat('plan_id=', new.plan_id),
        null,
        json_object(
            'plan_id', new.plan_id,
            'pet_id', new.pet_id,
            'medicine_id', new.medicine_id,
            'medicine_feed_time', new.medicine_feed_time,
            'medicine_feed_amount', new.medicine_feed_amount
        ),
        '新增喂药计划'
    );
end$$

create trigger trg_medicine_plan_log_update
after update on medicine_plan
for each row
begin
    call proc_write_operation_log(
        'UPDATE',
        'medicine_plan',
        concat('plan_id=', new.plan_id),
        json_object(
            'plan_id', old.plan_id,
            'pet_id', old.pet_id,
            'medicine_id', old.medicine_id,
            'medicine_feed_time', old.medicine_feed_time,
            'medicine_feed_amount', old.medicine_feed_amount
        ),
        json_object(
            'plan_id', new.plan_id,
            'pet_id', new.pet_id,
            'medicine_id', new.medicine_id,
            'medicine_feed_time', new.medicine_feed_time,
            'medicine_feed_amount', new.medicine_feed_amount
        ),
        '修改喂药计划'
    );
end$$

create trigger trg_medicine_plan_log_delete
after delete on medicine_plan
for each row
begin
    call proc_write_operation_log(
        'DELETE',
        'medicine_plan',
        concat('plan_id=', old.plan_id),
        json_object(
            'plan_id', old.plan_id,
            'pet_id', old.pet_id,
            'medicine_id', old.medicine_id,
            'medicine_feed_time', old.medicine_feed_time,
            'medicine_feed_amount', old.medicine_feed_amount
        ),
        null,
        '删除喂药计划'
    );
end$$

delimiter ;

use pet;

-- =========================
-- 九、数据库侧业务补充
-- =========================
DELETE mp
FROM medicine_plan mp
JOIN pet p
  ON mp.pet_id = p.pet_id
JOIN medicine m
  ON mp.medicine_id = m.medicine_id
WHERE p.pet_category <> m.medicine_category;

DELETE c
FROM cat c
JOIN pet p
  ON c.pet_id = p.pet_id
WHERE p.pet_category <> '猫';

DELETE d
FROM dog d
JOIN pet p
  ON d.pet_id = p.pet_id
WHERE p.pet_category <> '狗';

delimiter $$

drop trigger if exists trg_food_store_guard_insert$$
create trigger trg_food_store_guard_insert
before insert on food_store
for each row
begin
    if new.food_store_remaining_amount is null or new.food_store_remaining_amount <= 0 then
        signal sqlstate '45000'
        set message_text = '食品库存新增时，剩余量必须大于 0';
    end if;
end$$

drop trigger if exists trg_food_store_guard_update$$
create trigger trg_food_store_guard_update
before update on food_store
for each row
begin
    if new.food_store_remaining_amount is null then
        signal sqlstate '45000'
        set message_text = '食品库存剩余量不能为空';
    end if;

    if new.food_store_remaining_amount < 0 then
        signal sqlstate '45000'
        set message_text = '食品库存剩余量不能小于 0';
    end if;

    if new.food_store_remaining_amount = 0
       and coalesce(@allow_zero_food_store_remaining, 0) <> 1 then
        signal sqlstate '45000'
        set message_text = '食品库存手工维护时，剩余量必须大于 0';
    end if;
end$$

drop trigger if exists trg_medicine_store_guard_insert$$
create trigger trg_medicine_store_guard_insert
before insert on medicine_store
for each row
begin
    if new.medicine_store_remaining_amount is null or new.medicine_store_remaining_amount <= 0 then
        signal sqlstate '45000'
        set message_text = '药物库存新增时，剩余量必须大于 0';
    end if;
end$$

drop trigger if exists trg_medicine_store_guard_update$$
create trigger trg_medicine_store_guard_update
before update on medicine_store
for each row
begin
    if new.medicine_store_remaining_amount is null then
        signal sqlstate '45000'
        set message_text = '药物库存剩余量不能为空';
    end if;

    if new.medicine_store_remaining_amount < 0 then
        signal sqlstate '45000'
        set message_text = '药物库存剩余量不能小于 0';
    end if;

    if new.medicine_store_remaining_amount = 0
       and coalesce(@allow_zero_medicine_store_remaining, 0) <> 1 then
        signal sqlstate '45000'
        set message_text = '药物库存手工维护时，剩余量必须大于 0';
    end if;
end$$

drop trigger if exists trg_pet_category_sync_update$$
create trigger trg_pet_category_sync_update
after update on pet
for each row
begin
    declare v_cat_count int default 0;
    declare v_dog_count int default 0;

    if old.pet_category <> new.pet_category then
        delete from medicine_plan
        where pet_id = new.pet_id;

        if new.pet_category = '猫' then
            delete from dog
            where pet_id = new.pet_id;

            select count(*) into v_cat_count
            from cat
            where pet_id = new.pet_id;

            if v_cat_count = 0 then
                insert into cat(pet_id, cat_claw_cycle, cat_litter)
                values(new.pet_id, 14, null);
            else
                update cat
                set cat_claw_cycle = coalesce(cat_claw_cycle, 14)
                where pet_id = new.pet_id;
            end if;
        elseif new.pet_category = '狗' then
            delete from cat
            where pet_id = new.pet_id;

            select count(*) into v_dog_count
            from dog
            where pet_id = new.pet_id;

            if v_dog_count = 0 then
                insert into dog(pet_id, dog_walk_level, dog_license_no)
                values(new.pet_id, null, null);
            end if;
        end if;
    end if;
end$$

drop procedure if exists proc_execute_food_feed$$
create procedure proc_execute_food_feed(
    in p_owner_id int,
    in p_pet_id int,
    in p_food_id int,
    in p_amount int
)
begin
    declare v_pet_category char(1);
    declare v_food_category char(1);
    declare v_batch_no int;
    declare v_remaining_amount int;

    declare exit handler for sqlexception
    begin
        set @allow_zero_food_store_remaining = null;
        rollback;
        resignal;
    end;

    start transaction;

    if p_amount is null or p_amount <= 0 then
        signal sqlstate '45000'
        set message_text = '喂食量必须大于 0';
    end if;

    select pet_category into v_pet_category
    from pet
    where pet_id = p_pet_id
      and owner_id = p_owner_id
    limit 1;

    if v_pet_category is null then
        signal sqlstate '45000'
        set message_text = '未找到该主人的宠物';
    end if;

    select food_category into v_food_category
    from food
    where food_id = p_food_id
    limit 1;

    if v_food_category is null then
        signal sqlstate '45000'
        set message_text = '对应食物不存在';
    end if;

    if v_food_category <> v_pet_category then
        signal sqlstate '45000'
        set message_text = '食物适用动物与宠物种类不匹配，不能执行喂食';
    end if;

    select food_store_batch_no, food_store_remaining_amount
    into v_batch_no, v_remaining_amount
    from food_store
    where owner_id = p_owner_id
      and food_id = p_food_id
      and food_store_remaining_amount >= p_amount
    order by food_store_expire_time asc, food_store_batch_no asc
    limit 1
    for update;

    if v_batch_no is null then
        signal sqlstate '45000'
        set message_text = '没有可用食品批次可完成本次喂食';
    end if;

    set @allow_zero_food_store_remaining = 1;

    update food_store
    set food_store_remaining_amount = food_store_remaining_amount - p_amount
    where owner_id = p_owner_id
      and food_id = p_food_id
      and food_store_batch_no = v_batch_no;

    set @allow_zero_food_store_remaining = null;
    commit;
end$$

drop procedure if exists proc_execute_medicine_plan$$
create procedure proc_execute_medicine_plan(
    in p_plan_id int,
    in p_owner_id int,
    in p_medicine_batch_no int
)
begin
    declare v_medicine_id int;
    declare v_feed_amount int;
    declare v_selected_batch_no int;
    declare v_remaining_amount int;

    declare exit handler for sqlexception
    begin
        set @allow_zero_medicine_store_remaining = null;
        rollback;
        resignal;
    end;

    start transaction;

    select mp.medicine_id, mp.medicine_feed_amount
    into v_medicine_id, v_feed_amount
    from medicine_plan mp
    join pet p
      on mp.pet_id = p.pet_id
    where mp.plan_id = p_plan_id
      and p.owner_id = p_owner_id
    limit 1;

    if v_medicine_id is null then
        signal sqlstate '45000'
        set message_text = '未找到该主人的喂药计划';
    end if;

    if v_feed_amount is null or v_feed_amount <= 0 then
        signal sqlstate '45000'
        set message_text = '喂药量非法';
    end if;

    if p_medicine_batch_no is null then
        select medicine_batch_no, medicine_store_remaining_amount
        into v_selected_batch_no, v_remaining_amount
        from medicine_store
        where owner_id = p_owner_id
          and medicine_id = v_medicine_id
          and medicine_store_remaining_amount >= v_feed_amount
        order by medicine_store_expire_time asc, medicine_batch_no asc
        limit 1
        for update;

        if v_selected_batch_no is null then
            signal sqlstate '45000'
            set message_text = '没有可用药物批次可执行该计划';
        end if;
    else
        set v_selected_batch_no = p_medicine_batch_no;

        select medicine_store_remaining_amount
        into v_remaining_amount
        from medicine_store
        where owner_id = p_owner_id
          and medicine_id = v_medicine_id
          and medicine_batch_no = v_selected_batch_no
        for update;

        if v_remaining_amount is null then
            signal sqlstate '45000'
            set message_text = '未找到对应药物库存批次';
        end if;
    end if;

    if v_remaining_amount < v_feed_amount then
        signal sqlstate '45000'
        set message_text = '药物库存不足，无法执行喂药计划';
    end if;

    set @allow_zero_medicine_store_remaining = 1;

    update medicine_store
    set medicine_store_remaining_amount = medicine_store_remaining_amount - v_feed_amount
    where owner_id = p_owner_id
      and medicine_id = v_medicine_id
      and medicine_batch_no = v_selected_batch_no;

    set @allow_zero_medicine_store_remaining = null;
    commit;
end$$

delimiter ;
