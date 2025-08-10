local validator = {}

function validator.validate_parameter(value, expected_type, is_required, tag)
    if not is_required and not value then
        return
    end

    if is_required and not value then
        error(("%s is required."):format(tag))
    end

    if type(value) ~= expected_type then
        error(("%s is the wrong type, expected: '%s' actual: '%s'."):format(tag, expected_type, type(value)))
    end
end

return validator
