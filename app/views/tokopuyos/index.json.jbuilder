json.array!(@tokopuyos) do |tokopuyo|
  json.extract! tokopuyo, 
  json.url tokopuyo_url(tokopuyo, format: :json)
end
