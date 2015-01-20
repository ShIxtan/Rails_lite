module AuthHelper
  def form_authenticity_token
    session["authenticity_token"] ||= SecureRandom.urlsafe_base64(16)
  end
end
