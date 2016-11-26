namespace :lnwshop do

  desc 'Update subdomain list in text file'
  task :update_subdomain_list => :environment do
    LnwShopParser.new.update_subdomains
  end

  desc 'Import subdomains from text file to DB'
  task :import_subdomains_to_donors => :environment do
    LnwShopParser.new.import_subdomains_to_donors
  end

  desc 'Parse subdomain categories list'
  task :parse_subdomain_categories => :environment do
    Donor.where(parser_class: 'LnwShopParser').find_each do |lnw_donor|
      LnwShopParser.new('th', lnw_donor.domain).parse_category_tree
    end

    # parser_instance.parse_category_tree()
    # LnwShopParser.new.parse_subdomain_categories
  end

  # TODO: It should be run once!
  desc 'Add logo to subdomains'
  task :add_subdomain_logo => :environment do
    Donor.where(parser_class: 'LnwShopParser', logo_file_name: nil).find_each do |lnw_donor|
      LnwShopParser.new('th', lnw_donor.domain).add_subdomain_logo
    end
  end

end
