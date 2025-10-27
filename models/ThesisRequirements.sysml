// SysML v2 textual notation — Administrative & Planning Requirements
// for the MSc AI&ES graduation project (45 ECTS, 32 weeks)

package ThesisAdminAndPlanningRequirements {
    private import RequirementDerivation::*;
    private import ISQ::*;

    // ---------- Basic time constants ----------
    // SysML v2 ISQ has base 'second'; we define convenience multipliers.
    // Here we treat 1 day = 86400 s; 1 week = 7 * day; 1 month ~ 30 * day.
    // If your tool lacks time literals, bind via adapters.
    const day   :> ISQ::time = 86400 * second;
    const week  :> ISQ::time = 7 * day;
    const month :> ISQ::time = 30 * day;

    // ---------- System context ----------
    part graduationProject {
        // Program/weight
        attribute ectsCredits        :> Integer;
        attribute duration           :> ISQ::time;   // total registered duration
        attribute prepPhaseDuration  :> ISQ::time;   // phase 1
        attribute projectPhaseDuration :> ISQ::time; // phase 2

        // Calendar anchors (optional, for scheduling checks)
        attribute startRegistered    :> Boolean;
        attribute submissionOnEndDate:> Boolean;

        // Submission & event timing (measured or computed)
        attribute submitted          :> Boolean;
        attribute daysFromSubmitToPresentation :> ISQ::time; // working days target as calendar days proxy
        attribute weeksFromSubmitToDefense     :> ISQ::time;

        // Extension administration
        attribute extensionRequested :> Boolean;
        attribute extensionApproved  :> Boolean;
        attribute extensionDuration  :> ISQ::time;

        // Committee composition (voting members only)
        attribute committeeVotingMembers          :> Integer;  // total voting members (>=3)
        attribute committeeCrossGroupMemberPresent:> Boolean;  // at least one from different research group
        attribute committeeAssocOrFullCount       :> Integer;  // at least one associate/full professor

        // Assessment outcomes
        attribute categorySpecialization   :> Real; // 0..10
        attribute categoryResearchDesign   :> Real; // 0..10
        attribute categoryExecution        :> Real; // 0..10
        attribute categoryReport           :> Real; // 0..10
        attribute categoryPresentation     :> Real; // 0..10
        attribute finalGrade               :> Real; // rounded to nearest 0.5 by committee
        attribute assessmentComplete       :> Boolean;

        // Artifacts & integrity
        attribute researchPlanApproved     :> Boolean; // concludes prep phase
        attribute codeOfConductSigned      :> Boolean;
        attribute plagiarismChecked        :> Boolean;

        // Publicity / embargo administration
        attribute embargoRequested         :> Boolean;
        attribute embargoDuration          :> ISQ::time; // 0..2 years by default
        attribute publicSummaryProvided    :> Boolean;

        // Registration/admin
        attribute osirisRegistrationOk     :> Boolean; // study program approved + entry requirements met
    }

    // ---------- Generic requirement templates ----------
    requirement def EqualsTimeRequirement {
        subject t :> ISQ::time;
        attribute exact :> ISQ::time;
        require constraint { t == exact }
    }

    requirement def RangeTimeRequirement {
        subject t :> ISQ::time;
        attribute minT :> ISQ::time;
        attribute maxT :> ISQ::time;
        require constraint { (t >= minT) and (t <= maxT) }
    }

    requirement def MinCountRequirement {
        subject n :> Integer;
        attribute minN :> Integer;
        require constraint { n >= minN }
    }

    requirement def MinRealRequirement {
        subject x :> Real;
        attribute minX :> Real;
        require constraint { x >= minX }
    }

    requirement def BooleanTrueRequirement {
        subject ok :> Boolean;
        require constraint { ok == true }
    }

    requirement def MaxTimeRequirement {
        subject t :> ISQ::time;
        attribute maxT :> ISQ::time;
        require constraint { t <= maxT }
    }

    // ---------- Project-wide target (original) ----------
    requirement GraduationProjectCompliance {
        // Informal: The graduation project SHALL comply with AI&ES graduation procedure
        // (45 ECTS, 32 weeks, required phases, timing of submission/presentation/defense,
        // committee rules, assessment minima, plagiarism & integrity, registration).
    }

    // ---------- ECTS and Duration ----------
    requirement ECTSRequirement : MinCountRequirement {
        subject  :>> n = graduationProject.ectsCredits;
        attribute:>> minN = 45; // AI&ES graduation project = 45 ECTS
    }

    requirement DurationRequirement : EqualsTimeRequirement {
        subject  :>> t = graduationProject.duration;
        attribute:>> exact = 32 * week; // 32 weeks full-time without breaks
    }

    // ---------- Phase structure ----------
    requirement PreparationPhaseDurationRequirement : RangeTimeRequirement {
        subject  :>> t    = graduationProject.prepPhaseDuration;
        attribute:>> minT = 2 * week;
        attribute:>> maxT = 6 * week; // preparation phase is typically 2–6 weeks
    }

    requirement ProjectPhaseConsistencyRequirement {
        subject tPrep  :> ISQ::time;
        subject tProj  :> ISQ::time;
        subject tTotal :> ISQ::time;
        require constraint {
            tPrep  == graduationProject.prepPhaseDuration and
            tProj  == graduationProject.projectPhaseDuration and
            tTotal == graduationProject.duration and
            (tPrep + tProj) == tTotal
        }
    }

    requirement ResearchPlanApprovalRequirement : BooleanTrueRequirement {
        subject :>> ok = graduationProject.researchPlanApproved;
        // Informal: Research plan approved concludes the preparation phase.
    }

    // ---------- Registration & integrity ----------
    requirement RegistrationRequirement : BooleanTrueRequirement {
        subject :>> ok = graduationProject.osirisRegistrationOk;
        // Informal: study program approved; entry requirements met prior to start.
    }

    requirement CodeOfConductRequirement : BooleanTrueRequirement {
        subject :>> ok = graduationProject.codeOfConductSigned;
    }

    requirement PlagiarismCheckRequirement : BooleanTrueRequirement {
        subject :>> ok = graduationProject.plagiarismChecked;
    }

    // ---------- Submission & event timing ----------
    requirement SubmissionOnEndDateRequirement : BooleanTrueRequirement {
        subject :>> ok = graduationProject.submissionOnEndDate;
        // Informal: thesis is submitted no later than the registered end date.
    }

    requirement PresentationTimingRequirement : MaxTimeRequirement {
        subject  :>> t    = graduationProject.daysFromSubmitToPresentation;
        attribute:>> maxT = 5 * day; // presentation may be held 5 working days after submission
    }

    requirement DefenseTimingRequirement : MaxTimeRequirement {
        subject  :>> t    = graduationProject.weeksFromSubmitToDefense;
        attribute:>> maxT = 4 * week; // defense within 4 weeks after submission
    }

    // ---------- Extensions ----------
    requirement ExtensionPolicyRequirement {
        subject extReq :> Boolean;
        subject extApp :> Boolean;
        subject extDur :> ISQ::time;
        require constraint {
            // If extension is requested, it must be approved and ≤ 2 months
            (not extReq) or (extReq and extApp and (extDur <= (2 * month)))
        }
    } where {
        extReq = graduationProject.extensionRequested;
        extApp = graduationProject.extensionApproved;
        extDur = graduationProject.extensionDuration;
    }

    // ---------- Committee composition ----------
    requirement CommitteeSizeRequirement : MinCountRequirement {
        subject  :>> n     = graduationProject.committeeVotingMembers;
        attribute:>> minN  = 3; // at least 3 voting members
    }

    requirement CommitteeCrossGroupRequirement : BooleanTrueRequirement {
        subject :>> ok = graduationProject.committeeCrossGroupMemberPresent;
        // Informal: at least one voting member from a different research group.
    }

    requirement CommitteeSeniorityRequirement : MinCountRequirement {
        subject  :>> n    = graduationProject.committeeAssocOrFullCount;
        attribute:>> minN = 1; // at least one associate/full professor among voting members
    }

    // ---------- Assessment ----------
    requirement CategoryMinimumsRequirement {
        subject s :> Real;
        subject r :> Real;
        subject e :> Real;
        subject w :> Real;
        subject p :> Real;
        require constraint {
            s == graduationProject.categorySpecialization and s >= 5.0 and
            r == graduationProject.categoryResearchDesign and r >= 5.0 and
            e == graduationProject.categoryExecution and e >= 5.0 and
            w == graduationProject.categoryReport and w >= 5.0 and
            p == graduationProject.categoryPresentation and p >= 5.0
        }
    }

    requirement FinalGradeMinimumRequirement : MinRealRequirement {
        subject  :>> x    = graduationProject.finalGrade;
        attribute:>> minX = 6.0; // pass if final grade ≥ 6.0 (after rounding by committee)
    }

    requirement AssessmentCompleteRequirement : BooleanTrueRequirement {
        subject :>> ok = graduationProject.assessmentComplete;
    }

    // ---------- Embargo / public access ----------
    requirement EmbargoPolicyRequirement {
        subject embReq  :> Boolean;
        subject embDur  :> ISQ::time;
        subject pubSumm :> Boolean;
        require constraint {
            // If embargo requested:
            // - default ≤ 2 years
            // - public summary/version must be provided
            (not embReq) or (embReq and (embDur <= (2 * year)) and pubSumm)
        }
    } where {
        // If your tool lacks 'year', replace with 365*day
        const year :> ISQ::time = 365 * day;
        embReq  = graduationProject.embargoRequested;
        embDur  = graduationProject.embargoDuration;
        pubSumm = graduationProject.publicSummaryProvided;
    }

    // ---------- Derivation structure ----------
    #derivation connection {
        end #original ::> GraduationProjectCompliance;

        // Credit & duration
        end #derive ::> ECTSRequirement;
        end #derive ::> DurationRequirement;

        // Phase structure and research plan approval
        end #derive ::> PreparationPhaseDurationRequirement;
        end #derive ::> ProjectPhaseConsistencyRequirement;
        end #derive ::> ResearchPlanApprovalRequirement;

        // Registration & integrity
        end #derive ::> RegistrationRequirement;
        end #derive ::> CodeOfConductRequirement;
        end #derive ::> PlagiarismCheckRequirement;

        // Submission & events timing
        end #derive ::> SubmissionOnEndDateRequirement;
        end #derive ::> PresentationTimingRequirement;
        end #derive ::> DefenseTimingRequirement;

        // Extensions
        end #derive ::> ExtensionPolicyRequirement;

        // Committee
        end #derive ::> CommitteeSizeRequirement;
        end #derive ::> CommitteeCrossGroupRequirement;
        end #derive ::> CommitteeSeniorityRequirement;

        // Assessment
        end #derive ::> CategoryMinimumsRequirement;
        end #derive ::> FinalGradeMinimumRequirement;
        end #derive ::> AssessmentCompleteRequirement;

        // Publicity / embargo
        end #derive ::> EmbargoPolicyRequirement;
    }
}