local validator = {}

function validator.validate_parameter(value, expected_type, is_required, name)
    if is_required and not value then
        error(("%s is required."):format(name))
    end

    if type(value) ~= expected_type then
        error(("%s is the wrong type, expected: '%s' actual: '%s'."):format(name, expected_type, type(value)))
    end
end

return validator
