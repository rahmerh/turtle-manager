local file = {}

function file.write_to_file(content, file_name)
    local f = fs.open(file_name, "w")
    f.write(textutils.serialize(content))
    f.close()

    return true
end

return file
