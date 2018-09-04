require 'csv'
require 'levenshtein'

class API::V1::ValidationsController < ActionController::API
  IMPORTANT_HEADERS = [
    "first_name",
    "last_name",
    "email",
    "phone"
  ]

  def index
    header_indexes = []
    CSV.foreach("#{Rails.root}/storage/normal_data.csv", :headers => true) do |row|
      if header_indexes.empty?
        IMPORTANT_HEADERS.each do |header|
          header_indexes << (row.headers.index(header) - 1) # remove one for id
        end
      end

      # get rid of the ID for comparison sake since it's not actually part of the file.
      address = row.to_s.strip
      comma_index = address.index(",")
      address = address.slice((comma_index+1),address.length)

      # first check if the current row is a duplicate of any known duplicates
      next if check_known_duplicates(address, header_indexes)

      # then check if the current row is a duplicate of the rest of the entries logged
      next if check_unknown_duplicates(address, header_indexes)

      # if still haven't found duplicate then it's unique!
      non_duplicates << address
    end

    render json: {
        "status": "ok",
        "potential_duplicates": duplicates,
        "non_duplicates": non_duplicates
      }
  end

  private

  def duplicates
    @duplicates ||= {}
  end

  def non_duplicates
    @non_duplicates ||= []
  end

  def check_known_duplicates(address, header_indexes)
    duplicate_detected = false
    duplicates.values.each_with_index do |values, index|
      # ideally only need to check the first one since the others are also duplicates
      # enhancement: to be extra sure, additionally check all and if any match, add to array

      # check if address is very similar to entry, if not go further into comparing (ie. missing data)
      distance = Levenshtein.distance(address, values.first)
      if distance <= constraint
        # mark as duplicate
        duplicate_detected = true
        duplicates["duplicate_#{index+1}"] << address
        break
      end

      # naively remove commas from Company names (could be addressed better, or removed to begin with)
      # could have used a regex too, there are some really complex nifty ones
      split_address = remove_commas_from_company(address)
      split_entry = remove_commas_from_company(values.first)
      distances = calculate_distances(split_address, split_entry, header_indexes)

      # if more than half of the important headers are matching, consider this a duplicate
      # this could be done several different ways depending on what a company deems as the most important information. For example, emails could be highest priority and then name, maybe phone number is the unique key.
      # could also have determined that if the first and last name were less then 2 deviations different then it was a duplicate.
      if distances.count(0) > 2
        # mark as duplicate
        duplicate_detected = true
        duplicates["duplicate_#{index+1}"] << address
        break
      end

    end
    duplicate_detected
  end

  def check_unknown_duplicates(address, header_indexes)
    duplicate_detected = false
    non_duplicates.each_with_index do |entry, index|
      distance = Levenshtein.distance(address, entry)
      # check if address is very similar to entry, if not go further into comparing (ie. missing data)
      if distance <= constraint
        # mark as duplicate
        duplicate_detected = true
        duplicates["duplicate_#{duplicates.length + 1}"] = [entry, address]

        # remove from non_duplicates array
        non_duplicates.delete_at(index)
        break
      end

      # naively remove commas from Company names (could be addressed better, or removed to begin with)
      # could have used a regex too, there are some really complex nifty ones
      split_address = remove_commas_from_company(address)
      split_entry = remove_commas_from_company(entry)
      distances = calculate_distances(split_address, split_entry, header_indexes)

      # if more than half of the important headers are matching, consider this a duplicate
      # this could be done several different ways depending on what a company deems as the most important information. For example, emails could be highest priority and then name, maybe phone number is the unique key.
      # could also have determined that if the first and last name were less then 2 deviations different then it was a duplicate.
      if distances.count(0) > 2
        # mark as duplicate
        duplicate_detected = true
        duplicates["duplicate_#{duplicates.length + 1}"] = [entry, address]

        # remove from non_duplicates array
        non_duplicates.delete_at(index)

        break
      end
    end
    duplicate_detected
  end

  def remove_commas_from_company(address)
    if address.include?("\"")
      temp_address = address.split("\"")
      temp_address[1] = temp_address[1].gsub(",","")
      temp_address.join("").split(",")
    else
      address.split(",")
    end
  end

  def calculate_distances(split_address, split_entry, header_indexes)
    distances = []
    split_address.each_with_index do |field, index|
      if header_indexes.include?(index)
        distances << Levenshtein.distance(field, split_entry[index])
      end
    end
    distances
  end

  def constraint
    @constraint ||= (params[:constraint] ? params[:constraint].to_i : 5)
  end
end
