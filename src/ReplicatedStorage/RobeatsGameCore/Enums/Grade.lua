local Grade = {
    SS = 1;
    S = 2;
    A = 3;
    B = 4;
    C = 5;
    D = 6;
    F = 7;
}

local accuracy_to_grade = {
    [Grade.SS] = 100;
    [Grade.S] = 95;
    [Grade.A] = 90;
    [Grade.B] = 80;
    [Grade.C] = 70;
    [Grade.D] = 60;
    [Grade.F] = 50;
}

function Grade:get_grade_from_accuracy(accuracy)
    for enum_member, grade_acc in pairs(accuracy_to_grade) do
        if accuracy >= grade_acc then
            return enum_member
        end
    end
end

return Grade
