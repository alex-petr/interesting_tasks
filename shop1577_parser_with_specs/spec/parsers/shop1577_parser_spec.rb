require 'rails_helper'

RSpec.describe Shop1577Parser do

  before(:all) { @donor = create(:donor, domain: 'www.1577shop.com', parser_class: 'Shop1577Parser') }

  after(:all) { [Donor, DonorCategory].each(&:destroy_all) }

  let(:parser) { Shop1577Parser.new('th') }

  let(:parse_category_tree) { parser.parse_category_tree }

  it '#parse_category_tree: scrap and save donor categories' do
    # Run #parse_category_tree that should be tested
    parse_category_tree

    donor_categories = DonorCategory.where(donor_id: @donor.id)

    expect(donor_categories).not_to be_empty
  end

  it '#parse_categories_structure: scrap and save category products links' do
    parse_category_tree

    donor_category = DonorCategory.where(donor_id: @donor.id).leaves.first

    # Run #parse_categories_structure that should be tested and all connected jobs with first child category
    parser.parse_categories_structure donor_category.id
    ProductLinkWorker.drain

    donor_products = DonorProduct.where(donor_id: @donor.id)

    expect(donor_products).not_to be_empty
  end


  it '#parse_products: scrap and save products info' do
    parse_category_tree

    donor_category = DonorCategory.where(donor_id: @donor.id).leaves.first

    # Scrap links and run all jobs for links saving
    parser.parse_categories_structure donor_category.id
    ProductLinkWorker.drain

    # Run #parse_products that should be tested and all connected jobs
    parser.parse_products donor_category.id
    DonorProductUpdateWorker.drain
    DonorProductImageCreateWorker.drain

    donor_product       = DonorProduct.where(donor_id: @donor.id).first
    donor_product_image = DonorProductImage.find_by(donor_product_id: donor_product.id)

    # Test product data
    [:name, :price, :old_price, :saving, :image_url].each { |method| expect(donor_product.send(method)).not_to be_nil }

    # Test product image
    expect(donor_product_image).not_to be_nil
  end

  it '#update_prices: scrap and save product price' do
    parse_category_tree

    donor_category = DonorCategory.where(donor_id: @donor.id).leaves.first

    # Scrap links and run all jobs for links saving
    parser.parse_categories_structure donor_category.id
    ProductLinkWorker.drain

    donor_product = DonorProduct.where(donor_id: @donor.id).first

    # Run #update_prices that should be tested and all connected jobs, and reloads the record from the database
    parser.update_prices donor_product
    DonorProductUpdateWorker.drain
    donor_product.reload

    # Test product prices
    [:price, :old_price, :saving].each { |method| expect(donor_product.send(method)).not_to be_nil }
  end

end
