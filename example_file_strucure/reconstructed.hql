set
	hivevar:started_date = date_sub(current_date(), 90);

set
	hivevar:end_date = date_sub(current_date(), 2);
WITH msg_table AS (
    SELECT
        stat_dt,
        sms_send_dt,
        clk_tms,
        mb_no,
        send_yesterday,
        clk_success,
        send_minus_2_date,
        last_7_day_send_count,
        last_7_day_success_count,
        left_right_14_day_send_count,
        left_right_14_day_success_count
    FROM (
        SELECT
            stat_dt,
            send_minus_2_date,
            send_yesterday,
            sms_send_dt,
            clk_tms,
            mb_no,
            clk_success,
            COUNT(1) OVER (PARTITION BY mb_no ORDER BY unix_stat_dt RANGE BETWEEN 777600 PRECEDING AND 172800 PRECEDING) AS last_7_day_send_count,
            SUM(clk_success) OVER (PARTITION BY mb_no ORDER BY unix_stat_dt RANGE BETWEEN 777600 PRECEDING AND 172800 PRECEDING) AS last_7_day_success_count,
            COUNT(1) OVER (PARTITION BY mb_no ORDER BY unix_stat_dt RANGE BETWEEN 777600 PRECEDING AND 432000 FOLLOWING) AS left_right_14_day_send_count,
            SUM(clk_success) OVER (PARTITION BY mb_no ORDER BY unix_stat_dt RANGE BETWEEN 777600 PRECEDING AND 432000 FOLLOWING) AS left_right_14_day_success_count
        FROM (
            SELECT
                stat_dt,
                date_sub(stat_dt, 2) AS send_minus_2_date,
                date_sub(stat_dt, 1) AS send_yesterday,
                unix_timestamp(cast(stat_dt AS date)) AS unix_stat_dt,
                sms_send_dt,
                clk_tms,
                mb_no,
                CASE WHEN clk_tms > 0 THEN 1 ELSE 0 END AS clk_success
            FROM CX_HCZAPP_SAFE.DMD_ONSA_SGT_DYNA_SHRT_CLK_D t0
            WHERE stat_dt >= date_sub(${started_date}, 9) AND stat_dt <= date_add(${end_date}, 5)
            AND sms_tmpl_id LIKE '%chenmocuhuo%'
        ) t8
    ) t9
    WHERE stat_dt >= ${started_date} AND stat_dt <= ${end_date}
),
user_label AS (
    SELECT *
    FROM cx_dwf_safe.his_dwe_cus_insurance_xs_attr_d cc
    WHERE data_date >= date_sub(${started_date}, 2) AND data_date <= date_sub(${end_date}, 2)
    AND aopsid IS NOT NULL
    AND last_active_date >= "2022-01-01"
),
active_table AS (
    SELECT aopsid, mobilephone, active_date
    FROM (
        SELECT aopsid, active_date
        WHERE active_date >= ${started_date} AND active_date <= ${end_date}
        SELECT aopsid, active_date
        FROM cx_hczapp_safe.maom_maomdata_maom_user_daily_active_record aa
        GROUP BY aopsid, active_date
    ) t1
    LEFT JOIN 
    (
        SELECT aopsid, mobilephone
        FROM cx_dwf_safe.his_dwe_cus_insurance_xs_attr_d
        WHERE data_date = ${end_date}
        GROUP BY aopsid, mobilephone
    ) t2
    ON t1.aopsid = t2.aopsid
),
t3_active_table AS (
    -- if the user is active in the last 3 days, then the user is active
    SELECT mb_no, stat_dt, active_date
    FROM msg_table
    LEFT JOIN active_table
        ON msg_table.mb_no = active_table.mobilemodel
    WHERE
    active_date >= ${started_date} AND active_date <= ${end_date}
    WHERE 
      active_table.active_date >= message_table.stat_dt and
       active_table.active_date <= date_add(message_table.stat_dt, 3)
    GROUP BY aopsid, active_date
)


SELECT
    msg_table.*,
    CASE WHEN 
        t3_active_table.active_date IS NOT NULL THEN 1 
        ELSE 0 END 
    AS is_t3_huoyue,
    user_label.create_date,
    user_label.registe_days,
    user_label.mobilemodel,
    user_label.phone_os_type,
    user_label.phone_brand,
    user_label.active_cycle,
    user_label.last_active_date,
    user_label.active_7,
    user_label.active_30,
    user_label.active_60,
    user_label.active_90,
    user_label.active_180,
    user_label.lastest_30_city,
    user_label.is_car_days,
    user_label.purchase_price_default,
    user_label.is_new,
    user_label.insurance_begin_time,
    user_label.insurance_end_time,
    user_label.department_chinese_name_12,
    user_label.department_chinese_name_l4,
    user_label.birthday,
    user_label.age,
    user_label.is_qh_validate,
    user_label.user_query_vio_month,
    user_label.is_white_list,
    user_label.is_staff,
    user_label.is_open_wallet_account,
    user_label.phone_province,
    user_label.brand_name,
    user_label.ai_call_pick_prob,
    user_label.ai_call_pick_prob_rank_dp,
    user_label.ai_call_pick_prob_rank_dj,
    user_label.is_business_wechat_client,
    user_label.vehicle_age,
    user_label.vehicle_value,
    user_label.data_date,
    user_label.mb_no,
    rand() AS rand_index
FROM msg_table
LEFT JOIN user_label
    -- 我们在今天发送的短信，是在前天的用户标签上发送的
    -- 所以我们要把前天的用户标签和今天的短信表join起来
    -- 换句话说，今天只能看到前天的用户标签信息，如果我们今天发送短信，我们需要在后天才知道这个用户在发送短信那一天有没有活跃
    ON user_label.mobilephone = msg_table.mb_no AND 
    msg_table.send_minus_2_date = user_label.data_date
LEFT JOIN t3_active_table
    ON user_label.aopsid = t3_active_table.aopsid AND
    msg_table.stat_dt = t3_active_table.stat_dt
ORDER BY rand_index
 
