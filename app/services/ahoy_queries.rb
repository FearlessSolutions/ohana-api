module AhoyQueries
  module_function

  YESTERDAY = "Yesterday"
  LAST_7_DAYS = "Last 7 Days"
  LAST_30_DAYS = "Last 30 Days"
  LAST_MONTH = "Last Month"
  LAST_QUARTER = "Last Quarter"
  LAST_12_MONTHS = "Last 12 Months"

  DATE_RANGE_OPTIONS = [
    YESTERDAY,
    LAST_7_DAYS,
    LAST_30_DAYS,
    LAST_MONTH,
    LAST_QUARTER,
    LAST_12_MONTHS,
  ]

  def get_visits_by_location_and_date_range(location_id: , date_range:)
    Ahoy::Event.where(name: 'Location Visit', properties: {id: location_id}, time: interval_by_date_range(date_range)).count
  end

  def interval_by_date_range(date_range)
    today = Date.current.to_time(:utc).beginning_of_day
    yesterday_end = Date.yesterday.to_time(:utc).end_of_day

    case date_range
    when YESTERDAY
      (Date.yesterday.to_time(:utc).beginning_of_day..yesterday_end)
    when LAST_7_DAYS
      ((today - 7.days)..today.end_of_day)
    when LAST_30_DAYS
      ((today - 30.days)..today.end_of_day)
    when LAST_MONTH
      last_month = today.prev_month
      (last_month.beginning_of_month..last_month.end_of_month)
    when LAST_QUARTER
      prev_quarter = today.prev_quarter
      (prev_quarter.beginning_of_quarter..prev_quarter.end_of_quarter)
    when LAST_12_MONTHS
      ((today.prev_year)..today.end_of_day)
    else
      #not valid date range
    end
  end
end
