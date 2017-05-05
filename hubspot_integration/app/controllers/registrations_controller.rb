class RegistrationsController < Devise::RegistrationsController
  # POST /user
  def create
    build_resource(sign_up_params)

    is_production = Rails.env.staging? || Rails.env.production?

    # Try to find/create initial contact before user
    hubspot_contact = is_production ? HubspotService.new.find_or_create_contact(sign_up_params[:email]) : nil

    # If contact exists/created then proceed with user creation.
    if hubspot_contact || !is_production
      resource.save
      yield resource if block_given?
      if resource.persisted?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          # respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          # respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        # respond_with resource
      end
    end

    # If contact not created due to incorrect email then display error.
    resource.errors.add(:email, 'is invalid') if is_production && !hubspot_contact

    flash[:errors]   = resource.errors
    flash[:resource] = resource
    redirect_to sign_up_path
  end

  private

  def sign_up_params
    params.fetch(:user, {}).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end
end
