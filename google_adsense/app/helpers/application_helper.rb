module ApplicationHelper
  ##
  # Check if current host Thailand.
  def is_request_host_thai
    !is_request_host_indo
  end

  ##
  # Check if current host Indonesian.
  def is_request_host_indo
    'shopsmart.co.id' == request.host.squish
  end

  ##
  # Render Google AdSense advertising block of appropriate size.
  # Raise `KeyError` if required key `token` can’t be found.
  # @param [Hash] params
  def google_adsense(params)
    # Fill default keys and values.
    {size: :desktop_horizontal, class: '', id: ''}.each_pair { |key, value| params[key] = value unless params.key? key }
    # Raise `KeyError` if required key `token` can’t be found.
    params.fetch(:token)
    # Set `width`, `height`, `class` according to `size`.
    case params[:size]
      when :desktop_vertical
        params[:size] = { width: 300, height: 600 }
        params[:class] += ' hidden-xs visible-sm visible-lg'
      when :mobile # :tablet = { width: ?, height: ? }
        params[:size] = { width: 300, height: 250 }
        params[:class] += ' visible-xs'
      else # :desktop_horizontal
        params[:size] = { width: 728, height: 90 }
        params[:class] += ' hidden-xs visible-sm visible-lg'
    end
    render 'shared/google_adsense', { _class: params[:class], _id: params[:id], size: params[:size],
                                      token: params[:token] }
  end
end
