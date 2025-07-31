module PostsHelper
  def linkedin_urn_id(urn)
    urn.to_s.split(":").last
  end
end
