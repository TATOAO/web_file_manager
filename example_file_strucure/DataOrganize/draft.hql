set
	hivevar :started_date = date_sub(current_date(), 90);

set
	hivevar :end_date = date_sub(current_date(), 2);

select
	msg_table.*,
	active_table.*,
	case
		when active_table.active_date is not null then 1
		else 0
	end as is_huoyue,
	case
		when active_table.active_date is not null
		and msg_table.clk_tms > 0 then 1
		else 0
	end as is_clk_and_huoyue,
	create_date,
	registe_days,
	mobilemodel,
	phone_os_type,
	phone_brand,
	active_cycle,
	last_active_date,
	active_7,
	active_30,
	active_60,
	active_90,
	active_180,
	lastest_30_city,
	is_car_days,
	purchase_price_default,
	is_new,
	insurance_begin_time,
	insurance_end_time,
	department_chinese_name_12,
	department_chinese_name_l4,
	birthday,
	age,
	is_qh_validate,
	user_query_vio_month,
	is_white_list,
	is_staff,
	is_open_wallet_account,
	phone_province,
	brand_name,
	ai_call_pick_prob,
	ai_call_pick_prob_rank_dp,
	ai_call_pick_prob_rank_dj,
	is_business_wechat_client,
	vehicle_age,
	vehicle_value,
	data_date,
	mb_no,
	rand() as rand_index
from
	(
		select
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
		from
			(
				select
					stat_dt,
					send_minus_2_date,
					send_yesterday,
					sms_send_dt,
					clk_tms,
					mb_no,
					clk_success,
					count(1) over (
						partition by mb_no
						order by
							unix_stat_dt range between 777600 preceding
							and 172800 preceding
					) as last_7_day_send_count,
					sum(clk_success) over (
						partition by mb_no
						order by
							unix_stat_dt range between 777600 preceding
							and 172800 preceding
					) as last_7_day_success_count,
					count(1) over (
						partition by mb_no
						order by
							unix_stat_dt range between 777600 preceding
							and 432000 following
					) as left_right_14_day_send_count,
					sum(clk_success) over (
						partition by mb_no
						order by
							unix_stat_dt range between 777600 preceding
							and 432000 following
					) as left_right_14_day_success_count
				from
					(
						select
							stat_dt,
							date_sub(stat_dt, 2) as send_minus_2_date,
							date_sub(stat_dt, 1) as send_yesterday,
							unix_timestamp(cast(stat_dt as date)) as unix_stat_dt,
							sms_send_dt,
							clk_tms,
							mb_no,
							case
								when clk_tms > 0 then 1
								else 0
							end as clk_success
						from
							CX_HCZAPP_SAFE.DMD_ONSA_SGT_DYNA.SHRT_CLK_D
						where
							stat_dt >= date_sub(${started_date}, 9)
							and stat_dt <= date_add($ { end_date }, 5)
							and sms_tmpl_id like '%chenmocuhuo%'
					) t8
			) msg_table
		where
			stat_dt >= $ { started_date }
			and stat_dt <= $ { end_date }
	) msg_table
	left join (
		select
			*
		from
			cx_dwf_safe.his_dwe_cus_insurance_xs_attr_d_cc
		where
			data_date >= date_sub($ { started_date }, 2)
			and data_date <= date_sub($ { end_date }, 2)
			and aopsid is not null
			and last_active_date >= "2022-01-01"
	) user_label on user_label.mobilephone = msg_table.mb_no
	and msg_table.send_minus_2_date = user_label.data_date
	left join (
		select
			aopsid,
			active_date
		from
			cx_hczapp_safe.maom_maomdata_maom_user_daily_active_record aa
		where
			active_date >= $ { started_date }
			and active_date <= $ { end_date }
		group by
			aopsid,
			active_date
	) active_table on user_label.aopsid = active_table.aopsid
	and msg_table.stat_dt = active_table.active_date
order by
	rand_index