library("testthat")
library("CohortMethod")

set.seed(1234)
data(cohortMethodDataSimulationProfile)
sampleSize <- 1
cohortMethodData <- simulateCohortMethodData(cohortMethodDataSimulationProfile, n = sampleSize)

test_that("createStudyPop: washout period", {
  cohortMethodData$cohorts$rowId[1] <- 1
  cohortMethodData$cohorts$daysFromObsStart[1] <- 170
  sp <- createStudyPopulation(cohortMethodData = cohortMethodData,
                              washoutPeriod = 160)
  expect_equal(nrow(sp), 1)
  sp <- createStudyPopulation(cohortMethodData = cohortMethodData,
                              washoutPeriod = 180)
  expect_equal(nrow(sp), 0)
})

test_that("createStudyPop: firstExposureOnly", {
  tempCmd <- cohortMethodData
  tempCmd$cohorts <- rbind(tempCmd$cohorts, tempCmd$cohorts)
  tempCmd$cohorts$rowId[1] <- 1
  tempCmd$cohorts$daysFromObsStart[1] <- 200
  tempCmd$cohorts$rowId[2] <- 1
  tempCmd$cohorts$daysFromObsStart[2] <- 210

  sp <- createStudyPopulation(cohortMethodData = tempCmd,
                              firstExposureOnly = FALSE)
  expect_equal(nrow(sp), 2)
  sp <- createStudyPopulation(cohortMethodData = tempCmd,
                              firstExposureOnly = TRUE)
  expect_equal(nrow(sp), 1)
})

test_that("createStudyPop: removeDuplicateSubjects", {
  tempCmd <- cohortMethodData
  tempCmd$cohorts <- rbind(tempCmd$cohorts, tempCmd$cohorts)
  tempCmd$cohorts$rowId[1] <- 1
  tempCmd$cohorts$treatment[1] <- 0
  tempCmd$cohorts$rowId[2] <- 1
  tempCmd$cohorts$treatment[2] <- 1

  sp <- createStudyPopulation(cohortMethodData = tempCmd,
                              removeDuplicateSubjects = FALSE)
  expect_equal(nrow(sp), 2)
  sp <- createStudyPopulation(cohortMethodData = tempCmd,
                              removeDuplicateSubjects = TRUE)
  expect_equal(nrow(sp), 0)
})

test_that("createStudyPop: removeSubjectsWithPriorOutcome", {
  tempCmd <- cohortMethodData
  tempCmd$outcomes <- tempCmd$outcomes[1, ]
  tempCmd$outcomes$rowId[1] <- 1
  tempCmd$outcomes$daysToEvent[1] <- -10
  tempCmd$outcomes$outcomeId[1] <- 123

  sp <- createStudyPopulation(cohortMethodData = tempCmd,
                              outcomeId = 123,
                              removeSubjectsWithPriorOutcome = FALSE)
  expect_equal(nrow(sp), 1)
  sp <- createStudyPopulation(cohortMethodData = tempCmd,
                              outcomeId = 123,
                              removeSubjectsWithPriorOutcome = TRUE)
  expect_equal(nrow(sp), 0)
  sp <- createStudyPopulation(cohortMethodData = tempCmd,
                              outcomeId = 999,
                              removeSubjectsWithPriorOutcome = TRUE)
  expect_equal(nrow(sp), 1)
  sp <- createStudyPopulation(cohortMethodData = tempCmd,
                              outcomeId = 123,
                              removeSubjectsWithPriorOutcome = TRUE,
                              priorOutcomeLookback = 9)
  expect_equal(nrow(sp), 1)
})

test_that("createStudyPop: minDaysAtRisk", {
  cohortMethodData$cohorts$rowId[1] <- 1
  cohortMethodData$cohorts$daysToCohortEnd[1] <- 10
  cohortMethodData$cohorts$daysToObsEnd[1] <- 10

  sp <- createStudyPopulation(cohortMethodData = cohortMethodData,
                              minDaysAtRisk = 1,
                              addExposureDaysToEnd = TRUE)
  expect_equal(nrow(sp), 1)
  sp <- createStudyPopulation(cohortMethodData = cohortMethodData,
                              minDaysAtRisk = 20,
                              addExposureDaysToEnd = TRUE)
  expect_equal(nrow(sp), 0)
})

test_that("createStudyPop: risk window definition", {
  cohortMethodData$cohorts$rowId[1] <- 1
  cohortMethodData$cohorts$daysToCohortEnd[1] <- 10
  cohortMethodData$cohorts$daysToObsEnd[1] <- 20

  sp <- createStudyPopulation(cohortMethodData = cohortMethodData,
                              outcomeId = 123,
                              addExposureDaysToStart = FALSE,
                              riskWindowStart = 0,
                              addExposureDaysToEnd = TRUE,
                              riskWindowEnd = 0)
  expect_equal(sp$timeAtRisk, 11)

  sp <- createStudyPopulation(cohortMethodData = cohortMethodData,
                              outcomeId = 123,
                              addExposureDaysToStart = FALSE,
                              riskWindowStart = 1,
                              addExposureDaysToEnd = TRUE,
                              riskWindowEnd = 0)
  expect_equal(sp$timeAtRisk, 10)

  sp <- createStudyPopulation(cohortMethodData = cohortMethodData,
                              outcomeId = 123,
                              addExposureDaysToStart = FALSE,
                              riskWindowStart = 0,
                              addExposureDaysToEnd = FALSE,
                              riskWindowEnd = 9999)
  expect_equal(sp$timeAtRisk, 21)
})

test_that("createStudyPop: outcomes", {
  tempCmd <- cohortMethodData
  tempCmd$outcomes <- tempCmd$outcomes[1, ]
  tempCmd$outcomes$rowId[1] <- 1
  tempCmd$outcomes$daysToEvent[1] <- 15
  tempCmd$outcomes$outcomeId[1] <- 123
  tempCmd$cohorts$rowId[1] <- 1
  tempCmd$cohorts$daysToCohortEnd[1] <- 10
  tempCmd$cohorts$daysToObsEnd[1] <- 20

  sp <- createStudyPopulation(cohortMethodData = tempCmd,
                              outcomeId = 123,
                              riskWindowEnd = 999)
  expect_equal(sp$outcomeCount, 1)
  expect_equal(sp$survivalTime, 16)
  expect_equal(sp$daysToEvent, 15)

  sp <- createStudyPopulation(cohortMethodData = tempCmd,
                              outcomeId = 123,
                              riskWindowEnd = 0,
                              addExposureDaysToEnd = TRUE)
  expect_equal(sp$outcomeCount, 0)
  expect_equal(sp$survivalTime, 11)
})
