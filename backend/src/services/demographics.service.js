import { db } from "../config/db.js";  
import { NotFoundError, ValidationError, ForbiddenError } from "../utils/errors.js";  
  
export async function createDemographics(data, userId) {
  const { schoolId, academicYear, totalStudents, girlsCount, boysCount, passingRate, nationalExamScore } = data;

  const school = await db.school.findUnique({
    where: { id: schoolId }
  });

  if (!school) throw new NotFoundError("School not found");
  if (school.adminId !== userId) throw new ForbiddenError("You can only add demographics to your own school");

  const existing = await db.schoolDemographics.findUnique({
    where: { schoolId_academicYear: { schoolId, academicYear } }
  });

  if (existing) throw new ValidationError(`Demographics for academic year ${academicYear} already exist for this school`);

  return db.schoolDemographics.create({
    data: {
      schoolId,
      academicYear,
      totalStudents,
      girlsCount,
      boysCount,
      passingRate,
      nationalExamScore,
    },
  });
}  
  
export async function getSchoolDemographics(schoolId) {  
  const demographics = await db.schoolDemographics.findMany({  
    where: { schoolId },  
    orderBy: { academicYear: 'desc' },  
  });  
    
  return demographics;  
}  
  
export async function getDemographicsByYear(schoolId, academicYear) {  
  const demographics = await db.schoolDemographics.findUnique({  
    where: { schoolId_academicYear: { schoolId, academicYear } }  
  });  
    
  return demographics;  
}  
  
export async function updateDemographics(id, data, userId) {
  const existing = await db.schoolDemographics.findUnique({
    where: { id },
    include: { school: true }
  });

  if (!existing) throw new NotFoundError("Demographics record not found");
  if (existing.school.adminId !== userId) throw new ForbiddenError("You can only update demographics for your own school");

  return db.schoolDemographics.update({
    where: { id },
    data,
  });
}

export async function deleteDemographics(id, userId) {
  const existing = await db.schoolDemographics.findUnique({
    where: { id },
    include: { school: true }
  });

  if (!existing) throw new NotFoundError("Demographics record not found");
  if (existing.school.adminId !== userId) throw new ForbiddenError("You can only delete demographics for your own school");

  await db.schoolDemographics.delete({
    where: { id },
  });

  return { message: "Demographics deleted successfully" };
}