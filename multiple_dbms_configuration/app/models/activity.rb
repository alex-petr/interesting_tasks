class Activity < RedshiftRecord
  self.table_name = :activity

  def self.get_report_by(graph_period = 'hour', time_period = 'today', client_number, account_period)
    zone = ActiveSupport::TimeZone.find_tzinfo(Time.zone.name).identifier
    select_timestamp = case graph_period
                         when 'hour'
                           "date_trunc('hour', convert_timezone('#{zone}', date_call))"
                         when 'hour_of_day'
                           "extract(hour from convert_timezone('#{zone}', date_call))"
                         when 'day'
                           "date_trunc('day', convert_timezone('#{zone}', date_call))"
                         when 'day_of_week'
                           "to_char(convert_timezone('#{zone}', date_call), 'D'), " \
                           "to_char(convert_timezone('#{zone}', date_call), 'Dy')"
                         when 'week'
                           "date_trunc('week', convert_timezone('#{zone}', date_call))"
                         else
                           "date_trunc('month', convert_timezone('#{zone}', date_call))"
                       end

    today = Time.zone.now.beginning_of_day.utc
    time_range = case time_period
                   when 'today'
                     "date_call >= '#{today.to_s(:db)}'"
                   when 'yesterday'
                     "date_call >= '#{(today - 1.day).to_s(:db)}'" \
                     "AND date_call < '#{(today).to_s(:db)}'"
                   when 'last_seven_days'
                     "date_call >= '#{(today - 6.day).to_s(:db)}'"
                   when 'last_month'
                     month = Time.zone.now.beginning_of_month.utc
                     "date_call >= '#{month.to_s(:db)}'"
                   when 'this_billing_cycle'
                     billing = Billing.find_by_billing_id(client_number) # client_name(accounts.first)
                     billing = Billing.first unless billing
                     "date_call >= '#{billing.billing_cycle_start.to_s(:db)}' " \
                     "AND date_call <= '#{billing.billing_cycle_end.to_s(:db)}'"
                   else
                     year = Time.zone.now.beginning_of_year.utc
                     "date_call >= '#{year.to_s(:db)}'"
                 end

    group_by = graph_period == 'day_of_week' ? '1, 2' : '1'
    order_by = '1'

    client_number_condition = ('All Accounts' == client_number) ? '' : "AND client_account = '#{client_number}'"

    account_period_condition = ''

    if account_period.present?
      account_period_condition = " AND date_call >= '#{account_period[:start]}'"
      if account_period[:end].present?
        account_period_condition += " AND date_call <= '#{account_period[:end]}'"
      end
    end

    total_counts = find_by_sql('SELECT count(*) as total_calls, sum(minutes_total) as total_minutes, '\
                                    'avg(minutes_total) as avg_minutes '\
                                'FROM activity '\
                                "WHERE #{time_range}#{account_period_condition}"\
                                    "#{client_number_condition} AND (recording = '') IS FALSE")

    data_points = find_by_sql("SELECT #{select_timestamp} AS timestamp, count(*) as total_calls, "\
                                  'sum(minutes_total) as total_minutes, avg(minutes_total) as avg_minutes '\
                              'FROM activity '\
                              "WHERE #{time_range}#{account_period_condition}"\
                                  "#{client_number_condition} AND (recording = '') IS FALSE "\
                              "GROUP BY #{group_by}"\
                              "ORDER BY #{order_by} ASC;")

    graph_periods = %w(hour day week month)
    data_points.each do |data_point|
      if graph_periods.include? graph_period
        timestamp = data_point.timestamp.to_s(:db)
        data_point.timestamp = Time.zone.parse(timestamp)
      else
        data_point.timestamp = data_point.timestamp
      end
    end

    minutes_used = 0
    threshold = 0
    if accounts.length == 1
      billing = Billing.find_by_billing_id(client_number) # client_name(accounts.first)
      minutes_used = billing.try(:minutes_highlighted) || 0
      threshold = billing.try(:threshold) || 0
    end

    result = {
      total_calls: total_counts.first.total_calls,
      total_minutes: total_counts.first.total_minutes,
      avg_minutes: total_counts.first.avg_minutes,
      data_points: data_points,
      minutes_used: minutes_used,
      threshold: threshold
    }

    result
  end

  def self.accounts
    return @accounts if @accounts
    results = find_by_sql("SELECT CAST(coalesce(client_account, '0') AS bigint) as client_number, client_name "\
                          'FROM Activity '\
                          "WHERE CAST(coalesce(client_account, '0') AS bigint) > 9999 "\
                          'GROUP BY 1, 2 '\
                          'ORDER BY client_number;')

    @accounts = results
    # @accounts = []
    # results.each do |result|
    #   # @accounts << [result.client_number, result.client_name]
    # end

    @accounts
  end

  def as_json(options = {})
    super(except: %w(call_recid to_char))
  end
end
