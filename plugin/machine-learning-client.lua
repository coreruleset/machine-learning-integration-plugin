-- This is a driver code to point to different ML servers and models
-- and seek ml_inbound_status using such models
-- this ml driver is invoked by machine-learning-plugin-after.conf
-- currently most of this code is from https://github.com/coreruleset/coreruleset/pull/2067/files

-- Variable Declarations:
-- setting the machine learning server URL
local ml_server_url = 'http://127.0.0.1:5000/'
-- initialising the variable to return the machine learning pass or block status
local inbound_ml_result = 0

-- Importing libraries
local ltn12 = require("ltn12")
local http = require("socket.http")

function main()
  -- Initialising variables
  local method = m.getvar("REQUEST_METHOD")
  local path = m.getvar("REQUEST_FILENAME")
  local hour = m.getvar("TIME_HOUR")
  local day = m.getvar("TIME_DAY")
  local args = m.getvars("ARGS")
  local reqbody = m.getvars("REQUEST_BODY")
  local args_names = m.getvars("ARGS_NAMES")
  local request_header = m.getvars("REQUEST_HEADERS")
  local files = m.getvars("FILES")
  local filesizes = m.getvars("FILES_SIZES")
  local filenames = m.getvars("FILES_NAMES")
  local argsnamesstr = "{}"
  local args_str = "{}"
  local reqbodystr = ""
  local headersstr = "{}"
  local filesstr = "{}"
  local filesizestr = "{}"
  local filenamestr = "{}"
  local content_type = " " 
  local content_length = " "
  local headers = {}
  local req_data = {}
  local respbody = {}
  local body = " "
  req_data["req_protocol"] = m.getvar("REQUEST_PROTOCOL")
  req_data["req_uri"] = m.getvar("REQUEST_URI")
  req_data["req_method"] = m.getvar("REQUEST_METHOD")
  req_data["req_unique_id"] = m.getvar("UNIQUE_ID")
  req_data["file_name"] = m.getvar("REQUEST_FILENAME")
  req_data["base_name"] = m.getvar("REQUEST_BASENAME")
  req_data["headers_name"] = m.getvar("REQUEST_HEADERS_NAMES")

  -- Logging some variables
  m.log(4, "RequestProtocol: " ..req_data["req_protocol"])
  m.log(1, "RequestURI: " ..req_data["req_uri"])
  m.log(1, "RequestMethod: " ..req_data["req_method"])
  m.log(4, "RequestUniqueID: " ..req_data["req_unique_id"])
  m.log(1, "RequestFilename: " ..req_data["file_name"])
  m.log(1, "RequestBasename: " ..req_data["base_name"])
  m.log(1, "RequestHeadersName: " ..req_data["headers_name"])

  -- Parsing the tables and logging
  if request_header ~= nil then
    headersstr = "{"
    for k,v in pairs(request_header) do
      name = v["name"]
      value = v["value"]
      m.log(1, "name "..name)
      if name == "REQUEST_HEADERS:Content-Type" then
        content_type = value
      end
      if name == "REQUEST_HEADERS:Content-Length" then
        content_length = value
      end
      value = value:gsub('"', "$#$")
      headersstr = headersstr..'"'..name..'":"'..value..'",'
    end
    if #request_header == 0 then
      headersstr = "{}"
    else
      headersstr = string.sub(headersstr, 1, -2)
      headersstr = headersstr.."}"
    end
  end
  m.log(1, "Header "..headersstr)

  if reqbody ~= nil then
    reqbodystr = "{"
    for k,v in pairs(reqbody) do
      name = v["name"]
      value = v["value"]
      value = value:gsub('"', "$#$")
      reqbodystr = reqbodystr..'"'..name..'":"'..value..'",'
    end
    if #reqbody == 0 then
      reqbodystr = "{}"
    else
      reqbodystr = string.sub(reqbodystr, 1, -2)
      reqbodystr = reqbodystr.."}"
    end
  end
  m.log(1, "BODY "..reqbodystr)

  if args ~= nil then
    args_str = "{"
    for k,v in pairs(args) do
      name = v["name"]
      value = v["value"]
      value = value:gsub('"', "$#$")
      args_str = args_str..'"'..name..'":"'..value..'",'
    end
    if #args == 0 then
      args_str = "{}"
    else
      args_str = string.sub(args_str, 1, -2)
      args_str = args_str.."}"
    end
  end
  m.log(1, "Args "..args_str)

  if args_names ~= nil then
    argsnamesstr = "{"
    for k,v in pairs(args_names) do
      name = v["name"]
      value = v["value"]
      value = value:gsub('"', "$#$")
      argsnamesstr = argsnamesstr..'"'..name..'":"'..value..'",'
    end
    if #args_names == 0 then
      argsnamesstr = "{}"
    else
      argsnamesstr = string.sub(argsnamesstr, 1, -2)
      argsnamesstr = argsnamesstr.."}"
    end
  end
  m.log(1, "Args Names "..argsnamesstr)

  if files ~= nil then
    filesstr = "{"
    for k,v in pairs(files) do
      name = v["name"]
      value = v["value"]
      value = value:gsub('"', "$#$")
      filesstr = filesstr..'"'..name..'":"'..value..'",'
    end
    if #files == 0 then
      filesstr = "{}"
    else
      filesstr = string.sub(filesstr, 1, -2)
      filesstr = filesstr.."}"
    end
  end
  m.log(1, "Files "..filesstr)

  if filenames ~= nil then
    filenamestr = "{"
    for k,v in pairs(filenames) do
      name = v["name"]
      value = v["value"]
      value = value:gsub('"', "$#$")
      filenamestr = filenamestr..'"'..name..'":"'..value..'",'
    end
    if #filenames == 0 then
      filenamestr = "{}"
    else
      filenamestr = string.sub(filenamestr, 1, -2)
      filenamestr = filenamestr.."}"
    end
  end
  m.log(1, "Files Names"..filenamestr)

  if filesizes ~= nil then
    filesizestr = "{"
    for k,v in pairs(filesizes) do
      name = v["name"]
      value = v["value"]
      value = value:gsub('"', "$#$")
      filesizestr = filesizestr..'"'..name..'":"'..value..'",'
    end
    if #filesizes == 0 then
      filesizestr = "{}"
    else
      filesizestr = string.sub(filesizestr, 1, -2)
      filesizestr = filesizestr.."}"
    end
  end
  m.log(1, "File Sizes "..filesizestr)

  -- Construct http request for the ml server
  body = "method="..method.."&path="..path.."&args="..args_str.."&files="..filesstr.."&sizes="..filesizestr.."&hour="..hour.."&day="..day
  headers = {
    ["Content-Type"] = "application/x-www-form-urlencoded";
    ["Content-Length"] = #body
  }
  local source = ltn12.source.string(body)
  local client, code, headers, status = http.request{
    url=ml_server_url, 
    method='POST',
    source=source,
    headers=headers,
    sink = ltn12.sink.table(respbody)
  }
  respbody = table.concat(respbody)

-- Processing the result
  if client == nil then
    m.log(1, 'The server is unreachable \n')
  end
  if code == 401 then
    inbound_ml_result = 0
    m.log(1,'Anomaly found by ML')
  end
  if code == 200 then
    inbound_ml_result = 1
  end
  m.setvar("TX.inbound_ml_anomaly_score", respbody)
  m.setvar("TX.inbound_ml_status", inbound_ml_result)
  return inbound_ml_result
end
