# frozen_string_literal true
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read('../apikey.rb')

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(number)
  number = number.gsub(/[(),. -]/, '')
  if number.length == 10
    number
  elsif number.length == 11 && number[0] == '1'
    number[1..]
  else
    'Invalid number'
  end
end

def capture_dates(dates)
  dates.each do |row|
    registration_time = row[:regdate]
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

def clean_hours(hours)
  Time.parse(hours)
rescue ArgumentError
  '00:00'
end

def peak_hours_calc
  contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
  hours_obj = contents.map { |row| row[:regdate] }
  hours_obj.map! { |hour| Time.strptime(hour, '%m/%d/%y %H:%M') }
  peak_hours = hours_obj.map { |hour| hour.strftime('%k'.strip) }.tally
  peak_days = hours_obj.map { |hour| hour.strftime('%d/%m/%y'.strip) }
  calc_peak_days = peak_days.map { |days| Time.parse(days).wday }.tally
  result = week_day_subs(calc_peak_days).sort_by { |_, count| -count }
  print_this = result.sort_by { |_, count| -count }
  [peak_hours.sort_by { |_, count| -count }, print_this]
end

def week_day_subs(date_array)
  date_array.map.with_index do |week_data, _|
    case week_data[0]
    when 0
      ['Sunday', week_data[1]]
    when 1
      ['Monday', week_data[1]]
    when 2
      ['Tuesday', week_data[1]]
    when 3
      ['Wednesday', week_data[1]]
    when 4
      ['Thrusday', week_data[1]]
    when 5
      ['Friday', week_data[1]]
    when 6
      ['Saturday', week_data[1]]
  end
  end
end

p peak_hours_calc
 
# template_letter = File.read('../form_letter.erb')
# erb_template = ERB.new template_letter

# contents.each do |row|
  # id = row[0]
  # name = row[:first_name]
  # zipcode = clean_zipcode(row[:zipcode])
  # legislators = legislators_by_zipcode(zipcode)
  # clean_hours = clean_hours((row[:regdate]))
  # phone = clean_phone_numbers(row[:homephone])
  # p clean_hours
  # form_letter = erb_template.result(binding)
  # save_thank_you_letter(id, form_letter)
# end
