local _, ns = ...

ns.Util = ns.Util or {}

function ns.Util.AppendScript(frame, handler, func)
	local old = frame:GetScript(handler)
	frame:SetScript(handler, function( ... )
		if old ~= nil then
			old(...)
		end

		func(...)
	end)
end

function ns.Util.MergeFunc(f1, f2)
	if f1 == nil and f2 == nil then return end

	if f1 == nil and f2 then
		return f2
	end

	if f2 == nil and f1 then
		return f1
	end

	return function( ... )
		f1(...)
		f2(...)
	end
end