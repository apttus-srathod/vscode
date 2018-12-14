/**
 *
 * @author          Apttus
 * @date            6/1/2018
 * @description     This class contains helper methods for handling 
 *                  Apttus_Proposal__Proposal__c trigger events
 *
 ****************************************************************/

public class CPQ_ProposalTriggerHelper {

    
    public static void setRollupFields( Map<Id,Apttus_Proposal__Proposal__c> newMap, Map<Id,Apttus_Proposal__Proposal__c> oldMap ){

        try { CPQ_ProposalRollupService.doRollup( newMap ); }
        catch( Exception ex ) {
            SystemMessage.log( 'CPQ_ProposalRollupService method doRollup() failed.', ex );
        }
    }

    // TO DO : fix this ASAP as it does not account for bulk proposal updates
    private static Boolean isLegacyOppty = false;    

    // TO DO : refactor and break this up...
    public static void updateProposalLineItems(Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap){

        Map<Id,Apttus_Proposal__Proposal_Line_Item__c> LineItemToBeUpdatedMap = new Map<Id,Apttus_Proposal__Proposal_Line_Item__c>(); 

        set<Id> setFinalizedProposalIds = new set<Id>();
        set<Id> priceListIds = new set<Id>(); //BC-1496
        for(Apttus_Proposal__Proposal__c proposal : newMap.values()) {
            if(((oldMap.get(proposal.Id)).Apttus_QPConfig__ConfigurationFinalizedDate__c == null
                && proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != null)
               || 
               (oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != null
                && oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c) ) {
                    setFinalizedProposalIds.add(proposal.Id);
                    priceListIds.add(proposal.Apttus_QPConfig__PriceListId__c);
            }
        }            
        if(setFinalizedProposalIds.size() > 0) {
            List<Apttus_Proposal__Proposal_Line_Item__c> lisLine = [Select id,Apttus_Proposal__Proposal__c,Apttus_QPConfig__OptionId__r.Name,Tiered_Discount_Percentage__c,Apttus_QPApprov__Approval_Status__c, Discount_Tier_Ratio__c,Has_related_Pricing__c, Approval_Discount_Percentage__c,
                                                                            Apttus_Proposal__Proposal__r.OwnerId,Has_Zones__c, Apttus_QPConfig__LineNumber__c, Apttus_QPConfig__ChargeType__c,
                                                                            Apttus_QPConfig__AttributeValueId__c, Apttus_QPConfig__AttributeValueId__r.Suite__c, Apttus_QPConfig__LineType__c,
                                                                            Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c, Apttus_QPConfig__OptionId__c, 
                                                                            Product_Option_Family__c,Incremental_ARR_NRR__c, Product_Group__c, Apttus_Proposal__Product__r.Product_Grouping__c,
                                                                            Incremental_NetUnitPrice__c,Product_Option_Code__c,Apttus_QPConfig__Quantity2__c, Product_Option_SubFamily__c,
                                                                            Apttus_QPConfig__SellingFrequency__c, Gross_ARR_NRR__c, Apttus_QPConfig__PriceType__c, Apttus_Proposal__Proposal__r.Non_Standard_Term__c,
                                                                            Amount_Per_payment_Frequency_Number__c,Amount_Per_payment_Frequency__c, Apttus_QPConfig__LineStatus__c, Apttus_Proposal__Proposal__r.Payment_Frequency__c, 
                                                                            Suite_line_on_suite_bundle__c, Incremental_Quantity__c, Incremental_Net_Price__c,Apttus_Proposal__Product__r.Name,
                                                                            Apttus_QPConfig__OptionId__r.Product_Group__c, Apttus_Proposal__Product__r.Product_Group__c,Apttus_Proposal__Product__r.ProductCode,
                                                                            Has_Attribute_Changed__c, Apttus_QPConfig__AssetLineItemId__r.Apttus_Config2__AttributeValueId__c, Apttus_Proposal__Proposal__r.Quote_Type__c ,
                                                                            Delta_ARR_x__c,Delta_NRR__c,Apttus_QPConfig__SellingTerm__c, Product_sub_Family__c,Direct_Net_ARR_NRR__c,Delta_Net_ARR__c  from Apttus_Proposal__Proposal_Line_Item__c 
                                                                    where Apttus_Proposal__Proposal__c in :setFinalizedProposalIds];
            try{

                // TO DO : change this to user UserDataCache
                //Added by Anay Bhande: JIRA BC-555 
                Set<Id> setUserId=new Set<Id>();
                for(Id pId:setFinalizedProposalIds){
                    setUserId.add(newMap.get(pId).OwnerId);
                }
                Map<Id,User> mapUsers = new Map<Id,User>([Select id, ManagerId from User where Id in :setUserId]);
                //End of BC-555 

                //Added by Anay Bhande: JIRA BC-486 (Find non suite lines on bundles with suite selected)
                Set<String> SuiteSet=new Set<String>();
                Set<String> SuiteLineItemNumberSet=new Set<String>();
                for(Integer i=0;i<lisLine.size();i++){                    
                    if(lisLine[i].Apttus_QPConfig__AttributeValueId__c!=null && 
                      String.isNotBlank(lisLine[i].Apttus_QPConfig__AttributeValueId__r.Suite__c)){
                        SuiteLineItemNumberSet.add(LisLine[i].Apttus_Proposal__Proposal__c+String.valueOf(LisLine[i].Apttus_QPConfig__LineNumber__c));
                        SuiteSet.add(lisLine[i].Apttus_QPConfig__AttributeValueId__r.Suite__c);
                    }
                }    
      
                List<Apttus_Config2__ProductGroupMember__c> lisMembers = [Select Id, Apttus_Config2__ProductGroupId__c, Apttus_Config2__ProductGroupId__r.Name, 
                                                                                    Apttus_Config2__ProductId__c from Apttus_Config2__ProductGroupMember__c
                                                                                    where  Apttus_Config2__ProductGroupId__r.Name in :SuiteSet];


                Map<String, Set<Id> > SuiteToGroupMemberMap = new Map<String, Set<Id> >();
                for(Apttus_Config2__ProductGroupMember__c mem:lisMembers){
                    if(SuiteToGroupMemberMap.get(mem.Apttus_Config2__ProductGroupId__r.Name)!=NULL){
                        SuiteToGroupMemberMap.get(mem.Apttus_Config2__ProductGroupId__r.Name).add(mem.Apttus_Config2__ProductId__c);
                    }
                    else{
                        SuiteToGroupMemberMap.put(mem.Apttus_Config2__ProductGroupId__r.Name, new Set<Id> {mem.Apttus_Config2__ProductId__c});
                    }
                }

                //Check for Product group having names same as the suite and hide those lines
                //End of BC-486 

                //BC-3470
                List<Apttus_Config2__ProductConfiguration__c> lisConfig= [Select Id, Apttus_Config2__Status__c, Removed_Products__c, Apttus_QPConfig__Proposald__c from Apttus_Config2__ProductConfiguration__c 
                                                                        where Apttus_QPConfig__Proposald__c in :setFinalizedProposalIds and Apttus_Config2__Status__c=:CPQ_Constants.FINALIZED];

                for(Apttus_Proposal__Proposal__c proposal : newMap.values()){
                    proposal.Box_KeySafe_with_AWS_KMS_Setup_Removed__c=false;
                    proposal.Box_Governance_Setup_Removed__c=false;
                    proposal.Box_KS_with_AWS_CloudHSM_Setup_Removed__c=false;
                }
                
                for(Apttus_Config2__ProductConfiguration__c conf:lisConfig){
                    if(conf.Removed_Products__c != NULL){
                        if(conf.Removed_Products__c.contains(CPQ_Constants.KEYSAFEKMSSETUP_CODE)){
                            newMap.get(conf.Apttus_QPConfig__Proposald__c).Box_KeySafe_with_AWS_KMS_Setup_Removed__c=true;
                        }
                        if(conf.Removed_Products__c.contains(CPQ_Constants.GOVERNANCESETUP_CODE)){
                            newMap.get(conf.Apttus_QPConfig__Proposald__c).Box_Governance_Setup_Removed__c=true;
                        }
                        if(conf.Removed_Products__c.contains(CPQ_Constants.KEYSAFESETUP_CODE)){
                            newMap.get(conf.Apttus_QPConfig__Proposald__c).Box_KS_with_AWS_CloudHSM_Setup_Removed__c=true;
                        }
                    }   
                }
                //End of BC-3470

                // TO DO : move this logic to the proposal rollup service class
                //setRollupFields - Below method is added by shivani to update rollup fields on proposal object
                Map<Id,Double> ProposalToBox_ConsultingMap = new Map<Id,Double>();
                Map<Id,Double> ProposalToChannel_NRRMap = new Map<Id,Double>();
                Map<Id,Double> ProposalToTotalRecMap = new Map<Id,Double>();   
                Map<Id,Double> ProposalToTotal_Contract_EntitlementsMap = new Map<Id,Double>();
                Map<Id,Double> ProposalToSeats_SoldMap = new Map<Id,Double>();
                Map<Id,Double> ProposalToTCVRecMap = new Map<Id,Double>();
                Map<Id,Double> ProposalToTCVNonRecMap = new Map<Id,Double>();
                Map<Id,Double> ProposalToRenewalAmountMap = new Map<Id,Double>();
                Map<Id,Double> ProposalToNonRecNRRMap = new Map<Id,Double>();
                Map<Id,Double> ProposalToGrossSupportServiceAmount = new Map<Id,Double>();
                Map<Id,String> ContainsPremierandPlatinumServices = new Map<Id,String>();
                Map<Id,String> QuoteAccountTypeSold = new Map<Id,String>();

                Double TCVRec;
                Double TCVNonRec;
                Double Total_Rec;
                Decimal renewalAmount = 0;
                Decimal nonRecNRR = 0;
                Double Total_Contract_Entitlements = 0;
                Double Gross_Support_Services_Amount = 0;

                for(Id pId:setFinalizedProposalIds){
                    ProposalToTCVRecMap.put(pId,0);
                    ProposalToTCVNonRecMap.put(pId,0);
                    ProposalToTotalRecMap.put(pId,0);
                    ProposalToTotal_Contract_EntitlementsMap.put(pId,0);
                    ProposalToSeats_SoldMap.put(pId,0);
                    ProposalToRenewalAmountMap.put(pId,0);
                    ProposalToNonRecNRRMap.put(pId,0);
                    ProposalToGrossSupportServiceAmount.put(pId,0);
                    ContainsPremierandPlatinumServices.put(pId,null);
                    QuoteAccountTypeSold.put(pId,null);
                }
                //End of setRollupFields

                //Added by Mitul as part of BC-1281
                /*
                Description : This method handles update Attribute change indicator has_attribute_changed__c = TRUE
                Created by : Mitul Parmar
                Created Date : 05-Jun-2018*/
                
                Map<Id,Id> proposalLineProductAttributeMap = new Map<Id,Id>();
                Map<Id,Id> proposalLineAssetAttributeMap = new Map<Id,Id>();
                set<Id> productAttrSet = new Set<Id>();
                set<Id> assetAttrSet = new Set<Id>();

                Set<Id> optionProductIdSet = new Set<Id>();

                //check option product for getting getting product group name
                for(Apttus_Proposal__Proposal_Line_Item__c proposalLine : lisLine){

                  //this means that option is present so get the 
                  if(proposalLine.Apttus_QPConfig__OptionId__c != NULL) {
                    optionProductIdSet.add(proposalLine.Apttus_QPConfig__OptionId__c);
                  }
                }

                Map<Id,String> optionGroupMap = new  Map<Id,String>();
                set<Id> licenseOptionIds = new set<Id>();
                set<String> groupMemberSet = new set<String>{CPQ_constants.BOX_PRODUCT_GROUP_ZONE,CPQ_constants.BOX_PRODUCT_GROUP_ALL_PLATFORM,CPQ_constants.CORE_LICENSES};
                List<Apttus_Config2__ProductGroupMember__c> productGroupMemberList = [Select Id, Apttus_Config2__ProductGroupId__r.Name , Apttus_Config2__ProductId__c 
                                                                                        from Apttus_Config2__ProductGroupMember__c where Apttus_Config2__ProductId__c in :optionProductIdSet 
                                                                                        AND Apttus_Config2__ProductGroupId__r.Name IN :groupMemberSet ];
                //update map to check product
                system.debug('@--- '+productGroupMemberList.size());
                for(Apttus_Config2__ProductGroupMember__c groupMember : productGroupMemberList) {
                    if(groupMember.Apttus_Config2__ProductGroupId__r.Name == CPQ_constants.CORE_LICENSES) {
                        licenseOptionIds.add(groupMember.Apttus_Config2__ProductId__c);
                        system.debug('@---- '+licenseOptionIds);
                    }
                    else
                        optionGroupMap.put(groupMember.Apttus_Config2__ProductId__c, groupMember.Apttus_Config2__ProductGroupId__r.Name);
                }

                //start BC-1496
                Map<Id,list<Approval_Discounting_Dimension__c>> approvalDiscounts = new Map<Id,List<Approval_Discounting_Dimension__c>>();  
                for(Approval_Discounting_Dimension__c discountSO : [SELECT Id,Threshold_Value__c,Start_Tier__c,Ending_Tier__c,Is_Attribute__c,Approval_Discount_Type__c,Product__c FROM Approval_Discounting_Dimension__c WHERE Product__c IN : optionProductIdSet AND Price_List_Name__c IN : priceListIds]) {

                  if(approvalDiscounts.containsKey(discountSO.Product__c))
                    approvalDiscounts.get(discountSO.Product__c).add(discountSO);
                  else
                    approvalDiscounts.put(discountSO.Product__c, new list<Approval_Discounting_Dimension__c>{discountSO});
                }
                system.debug('@--- '+approvalDiscounts);
                //End BC-1496
                system.debug('@@-- '+optionGroupMap);
                List<Apttus_Proposal__Proposal_Line_Item__c> finalProposalLineList = new List<Apttus_Proposal__Proposal_Line_Item__c>();
                Map<Id,Apttus_Proposal__Proposal_Line_Item__c> bundleIdToLicenseOption = new Map<Id,Apttus_Proposal__Proposal_Line_Item__c>();
                //system.debug('Inside setAttributeChangeIndicator lisLine -- '+lisLine.size());
                for(Apttus_Proposal__Proposal_Line_Item__c proposalLine : lisLine){    

                    if(licenseOptionIds.contains(proposalLine.Apttus_QPConfig__OptionId__c))  
                        bundleIdToLicenseOption.put(proposalLine.Apttus_Proposal__Product__c,proposalLine);

                    if(newMap.get(proposalLine.Apttus_Proposal__Proposal__c).Quote_Type__c == CPQ_constants.UPSELL || newMap.get(proposalLine.Apttus_Proposal__Proposal__c).Quote_Type__c == CPQ_constants.RENEWAL){
                        if(proposalLine.Apttus_QPConfig__OptionId__c != NULL && optionGroupMap.containsKey(proposalLine.Apttus_QPConfig__OptionId__c)
                          && String.isNotBlank(optionGroupMap.get(proposalLine.Apttus_QPConfig__OptionId__c)) 
                          && (optionGroupMap.get(proposalLine.Apttus_QPConfig__OptionId__c).contains(CPQ_constants.BOX_PRODUCT_GROUP_ZONE) || 
                            optionGroupMap.get(proposalLine.Apttus_QPConfig__OptionId__c).contains(CPQ_constants.BOX_PRODUCT_GROUP_ALL_PLATFORM))) {

                            //system.debug('proposalLine.Apttus_QPConfig__OptionId__r.Product_Group__c :-- '+optionGroupMap.get(proposalLine.Apttus_QPConfig__OptionId__c));
                          finalProposalLineList.add(proposalLine);
                          //fill both map for one to one mapping between Proposal line vs product proposal attribute value
                          // and proposal line vs Asset attribute value
                          proposalLineProductAttributeMap.put(proposalLine.Id, proposalLine.Apttus_QPConfig__AttributeValueId__c);
                          proposalLineAssetAttributeMap.put(proposalLine.Id, proposalLine.Apttus_QPConfig__AssetLineItemId__r.Apttus_Config2__AttributeValueId__c );
                          productAttrSet.add(proposalLine.Apttus_QPConfig__AttributeValueId__c);
                          assetAttrSet.add(proposalLine.Apttus_QPConfig__AssetLineItemId__r.Apttus_Config2__AttributeValueId__c);
                        } 
                        else if(proposalLine.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c == CPQ_constants.BUNDLE
                          && proposalLine.Apttus_QPConfig__OptionId__c == NULL){
                         system.debug('==proposalLine=='+proposalLine + '==proposalLine.Apttus_QPConfig__AttributeValueId__c=='+proposalLine.Apttus_QPConfig__AttributeValueId__c + '==proposalLine.Apttus_QPConfig__AssetLineItemId__r.Apttus_Config2__AttributeValueId__c=='+proposalLine.Apttus_QPConfig__AssetLineItemId__r.Apttus_Config2__AttributeValueId__c);
                          //system.debug('proposalLine.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c :-- '+proposalLine.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c);
                          finalProposalLineList.add(proposalLine);
                          //fill both map for one to one mapping between Proposal line vs product proposal attribute value
                          // and proposal line vs Asset attribute value
                          proposalLineProductAttributeMap.put(proposalLine.Id, proposalLine.Apttus_QPConfig__AttributeValueId__c);
                          proposalLineAssetAttributeMap.put(proposalLine.Id, proposalLine.Apttus_QPConfig__AssetLineItemId__r.Apttus_Config2__AttributeValueId__c );
                          productAttrSet.add(proposalLine.Apttus_QPConfig__AttributeValueId__c);
                          assetAttrSet.add(proposalLine.Apttus_QPConfig__AssetLineItemId__r.Apttus_Config2__AttributeValueId__c);
                        }
                    }
                }
            
                Map<Id,Apttus_Config2__AssetAttributeValue__c> assetAttributeValueMap = new Map<Id,Apttus_Config2__AssetAttributeValue__c>();
                Map<Id,Apttus_QPConfig__ProposalProductAttributeValue__c> productAttributeValueMap = new Map<Id,Apttus_QPConfig__ProposalProductAttributeValue__c>();

                //query to populate proposal product attribute value records
                String proposalAttributeQuery = '';
                for(Schema.FieldSetMember f : SObjectType.Apttus_QPConfig__ProposalProductAttributeValue__c.FieldSets.Change_Custom_Attribute.getFields()) {
                    proposalAttributeQuery += f.getFieldPath() + ', ';
                }
                String proposalQuery = 'SELECT ' + proposalAttributeQuery +' Id '+
                            ' FROM Apttus_QPConfig__ProposalProductAttributeValue__c ' + 
                            ' WHERE Id in :productAttrSet';
                //system.debug('Proposal Attribute Query :-- '+proposalAttributeQuery);
                List<Apttus_QPConfig__ProposalProductAttributeValue__c> proposalAttrList = Database.query(proposalQuery);


                //query to populate Asset Attribute Value records
                String assetAttributeQuery = '';
                for(Schema.FieldSetMember f : SObjectType.Apttus_Config2__AssetAttributeValue__c.FieldSets.Change_Custom_Attribute.getFields()) {
                    assetAttributeQuery += f.getFieldPath() + ', ';
                }
                String assetQuery = 'SELECT ' + assetAttributeQuery +' Id '+
                            ' FROM Apttus_Config2__AssetAttributeValue__c ' + 
                            ' WHERE Id in :assetAttrSet';
                //system.debug('Asset Attribute Query :-- '+assetAttributeQuery);
                List<Apttus_Config2__AssetAttributeValue__c> assetAttrList = Database.query(assetQuery);
                

                for(Apttus_Config2__AssetAttributeValue__c attr : assetAttrList){
                    assetAttributeValueMap.put(attr.Id, attr);
                }

                for(Apttus_QPConfig__ProposalProductAttributeValue__c attr : proposalAttrList){
                    productAttributeValueMap.put(attr.Id, attr);
                }


                //logic to identify each proposal line item against the valid asset attribute value and product proposal attribute value.
                system.debug('@@-- '+bundleIdToLicenseOption);
                for(Apttus_Proposal__Proposal_Line_Item__c proposalLine : finalProposalLineList){

                    if(proposalLineProductAttributeMap.containsKey(proposalLine.Id) && proposalLineAssetAttributeMap.containsKey(proposalLine.Id)){

                      //validate the change in attributes for each proposal line item
                      Id proposalAttributeValueId = proposalLineProductAttributeMap.get(proposalLine.Id);
                      Id assetAttributeValueId = proposalLineAssetAttributeMap.get(proposalLine.Id);

                      if(assetAttributeValueMap.containsKey(assetAttributeValueId) && productAttributeValueMap.containsKey(proposalAttributeValueId)){

                          //check for change in attribute value
                          if(checkDifferenceForValue(assetAttributeValueMap.get(assetAttributeValueId) , productAttributeValueMap.get(proposalAttributeValueId))){

                            //update flag and add it for update.
                            if(LineItemToBeUpdatedMap.containsKey(proposalLine.Id)){
                                LineItemToBeUpdatedMap.get(proposalLine.Id).Has_Attribute_Changed__c=true;
                            }
                            else{
                                LineItemToBeUpdatedMap.put(proposalLine.Id,proposalLine);
                                LineItemToBeUpdatedMap.get(proposalLine.Id).Has_Attribute_Changed__c=true;
                            }
                            if(bundleIdToLicenseOption.containsKey(proposalLine.Apttus_Proposal__Product__c) &&  proposalLine.Apttus_QPConfig__OptionId__c == NULL) {
                                LineItemToBeUpdatedMap.put(bundleIdToLicenseOption.get(proposalLine.Apttus_Proposal__Product__c).Id,bundleIdToLicenseOption.get(proposalLine.Apttus_Proposal__Product__c));
                                LineItemToBeUpdatedMap.get(bundleIdToLicenseOption.get(proposalLine.Apttus_Proposal__Product__c).Id).Has_Attribute_Changed__c=true;
                            }
                          }
                      }
                    }
                }


                //End of BC-1281

                for(Integer i=0;i<lisLine.size();i++){

                    //Added by Anay Bhande: JIRA BC-486 (Find non suite lines on bundles with suite selected)
                    if(SuiteLineItemNumberSet.contains(LisLine[i].Apttus_Proposal__Proposal__c+String.valueOf(LisLine[i].Apttus_QPConfig__LineNumber__c))){
                        if(LisLine[i].Apttus_QPConfig__LineType__c==CPQ_Constants.OPTION){
                            if(SuiteToGroupMemberMap.get(LisLine[i].Apttus_QPConfig__AttributeValueId__r.Suite__c)!=NULL
                              && SuiteToGroupMemberMap.get(LisLine[i].Apttus_QPConfig__AttributeValueId__r.Suite__c).contains(LisLine[i].Apttus_QPConfig__OptionId__c)){
                                if(LineItemToBeUpdatedMap.containsKey(lisLine[i].Id)){
                                    LineItemToBeUpdatedMap.get(lisLine[i].Id).Suite_line_on_suite_bundle__c=true;
                                }
                                else{
                                    LineItemToBeUpdatedMap.put(lisLine[i].Id,lisLine[i]);
                                    LineItemToBeUpdatedMap.get(lisLine[i].Id).Suite_line_on_suite_bundle__c=true;
                                }
                            }
                        }
                        else if(LisLine[i].Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c==CPQ_Constants.STANDALONE){
                            if(LineItemToBeUpdatedMap.containsKey(lisLine[i].Id)){
                                LineItemToBeUpdatedMap.get(lisLine[i].Id).Suite_line_on_suite_bundle__c=true;
                            }
                            else{
                                LineItemToBeUpdatedMap.put(lisLine[i].Id,lisLine[i]);
                                LineItemToBeUpdatedMap.get(lisLine[i].Id).Suite_line_on_suite_bundle__c=true;
                            }                            
                        }
                        else if(LisLine[i].Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c==CPQ_Constants.BUNDLE && LisLine[i].Apttus_QPConfig__ChargeType__c==CPQ_Constants.SUITE_SUBSCRIPTION_FEE){
                            if(LineItemToBeUpdatedMap.containsKey(lisLine[i].Id)){
                                LineItemToBeUpdatedMap.get(lisLine[i].Id).Suite_line_on_suite_bundle__c=true;
                            }
                            else{
                                LineItemToBeUpdatedMap.put(lisLine[i].Id,lisLine[i]);
                                LineItemToBeUpdatedMap.get(lisLine[i].Id).Suite_line_on_suite_bundle__c=true;
                            }                            
                        }
                    }
                    //End of BC-486 

                    //start BC-1496
                    Boolean isIBMPricelist=false;
                    set<String> productWithZones = new set<String>(System.Label.CPQ_ProductName.split(';'));
                    if(approvalDiscounts.keySet().size() > 0 && lisLine[i].Apttus_QPConfig__OptionId__c <> null && approvalDiscounts.containsKey(lisLine[i].Apttus_QPConfig__OptionId__c)) {
                        isIBMPricelist=true;
                        for(Approval_Discounting_Dimension__c discountSO : approvalDiscounts.get(lisLine[i].Apttus_QPConfig__OptionId__c)) {
                            if(lisLine[i].Apttus_QPConfig__Quantity2__c >= discountSO.Start_Tier__c && lisLine[i].Apttus_QPConfig__Quantity2__c < discountSO.Ending_Tier__c) {

                                if(!LineItemToBeUpdatedMap.containsKey(lisLine[i].Id))
                                    LineItemToBeUpdatedMap.put(lisLine[i].Id,lisLine[i]);
                                if(discountSO.Approval_Discount_Type__c == CPQ_constants.FLOOR_PRICE && discountSO.Threshold_Value__c > 0 && lisLine[i].Incremental_NetUnitPrice__c < discountSO.Threshold_Value__c) {
                                    if(lisLine[i].Has_Zones__c == discountSO.Is_Attribute__c && discountSO.Is_Attribute__c && productWithZones.contains(lisLine[i].Apttus_QPConfig__OptionId__r.Name)) {
                                        LineItemToBeUpdatedMap.get(lisLine[i].Id).Tiered_Discount_Percentage__c = (1-(lisLine[i].Incremental_NetUnitPrice__c/discountSO.Threshold_Value__c))*100;
                                        system.debug('@----@ '+LineItemToBeUpdatedMap.get(lisLine[i].Id).Id);
                                        system.debug('@----@ '+LineItemToBeUpdatedMap.get(lisLine[i].Id).Tiered_Discount_Percentage__c);
                                        break;
                                    }
                                    else if(!discountSO.Is_Attribute__c) {
                                        LineItemToBeUpdatedMap.get(lisLine[i].Id).Tiered_Discount_Percentage__c = (1-(lisLine[i].Incremental_NetUnitPrice__c/discountSO.Threshold_Value__c))*100;
                                        break;
                                    }
                                }
                                else if(discountSO.Approval_Discount_Type__c == CPQ_constants.PERCENTAGE && discountSO.Threshold_Value__c <> null){
                                    if(discountSO.Threshold_Value__c == 0 && lisLine[i].Has_related_Pricing__c) {
                                        isIBMPricelist=false;
                                    }
                                    else if(lisLine[i].Actual_Base_Price__c <> null && lisLine[i].Actual_Base_Price__c > 0 && lisLine[i].Incremental_NetUnitPrice__c <> null){
                                        Decimal percentage = (lisLine[i].Actual_Base_Price__c-lisLine[i].Incremental_NetUnitPrice__c)/lisLine[i].Actual_Base_Price__c;
                                        if(percentage > discountSO.Threshold_Value__c)
                                            LineItemToBeUpdatedMap.get(lisLine[i].Id).Tiered_Discount_Percentage__c = percentage - discountSO.Threshold_Value__c;
                                    }
                                }
                            }
                        }
                    }
                    else {
                        isIBMPricelist=false;
                    }
                    //end BC-1496

                    //BC-3314

                    Double Discount_Tier_Ratio=1;
                    if(lisline[i].Product_Option_Code__c==CPQ_Constants.boxKeysafeAWSCloudHSMCode){
                        if(lisline[i].Apttus_QPConfig__Quantity2__c<=2500)
                        Discount_Tier_Ratio=1;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=5000)
                        Discount_Tier_Ratio=0.6;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=10000)
                        Discount_Tier_Ratio=0.5333;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=25000)
                        Discount_Tier_Ratio=0.4667;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=50000)
                        Discount_Tier_Ratio=0.4;
                        else
                        Discount_Tier_Ratio=0.3333;
                    }
                    else if(lisline[i].Product_Option_Code__c==CPQ_Constants.BOX_GXP_CODE){
                        if(lisline[i].Apttus_QPConfig__Quantity2__c<=500)
                        Discount_Tier_Ratio=1;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=1000)
                        Discount_Tier_Ratio=0.75;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=2500)
                        Discount_Tier_Ratio=0.5;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=5000)
                        Discount_Tier_Ratio=0.35;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=10000)
                        Discount_Tier_Ratio=0.25;
                        else
                        Discount_Tier_Ratio=0.2;
                    }
                    else if(lisline[i].Product_Option_Code__c==CPQ_Constants.boxKeysafeAWSKMSCode){
                        if(lisline[i].Apttus_QPConfig__Quantity2__c<=250)
                        Discount_Tier_Ratio=1;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=500)
                        Discount_Tier_Ratio=0.8;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=1000)
                        Discount_Tier_Ratio=0.6;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=2500)
                        Discount_Tier_Ratio=0.4;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=5000)
                        Discount_Tier_Ratio=0.36;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=10000)
                        Discount_Tier_Ratio=0.32;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=25000)
                        Discount_Tier_Ratio=0.28;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=50000)
                        Discount_Tier_Ratio=0.24;
                        else
                        Discount_Tier_Ratio=0.2;
                    }
                    else if((lisLine[i].Apttus_QPConfig__OptionId__r.Product_Group__c != NULL && lisLine[i].Apttus_QPConfig__OptionId__r.Product_Group__c.contains(CPQ_constants.CORE_LICENSES)) || lisLine[i].Suite_line_on_suite_bundle__c){
                        if(lisline[i].Apttus_QPConfig__Quantity2__c<=50 || (lisline[i].Apttus_QPConfig__Quantity2__c<=250 && lisline[i].Product_sub_Family__c == CPQ_Constants.enterprisePlus))
                        Discount_Tier_Ratio=1;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=100 || (lisline[i].Apttus_QPConfig__Quantity2__c<=500 && lisline[i].Product_sub_Family__c == CPQ_Constants.enterprisePlus))
                        Discount_Tier_Ratio=0.94;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=250 || (lisline[i].Apttus_QPConfig__Quantity2__c<=1000 && lisline[i].Product_sub_Family__c == CPQ_Constants.enterprisePlus))
                        Discount_Tier_Ratio=0.86;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=500 || (lisline[i].Apttus_QPConfig__Quantity2__c<=2500 && lisline[i].Product_sub_Family__c == CPQ_Constants.enterprisePlus))
                        Discount_Tier_Ratio=0.77;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=1000 || (lisline[i].Apttus_QPConfig__Quantity2__c<=5000 && lisline[i].Product_sub_Family__c == CPQ_Constants.enterprisePlus))
                        Discount_Tier_Ratio=0.69;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=2500 || (lisline[i].Apttus_QPConfig__Quantity2__c<=10000 && lisline[i].Product_sub_Family__c == CPQ_Constants.enterprisePlus))
                        Discount_Tier_Ratio=0.57;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=5000 || (lisline[i].Apttus_QPConfig__Quantity2__c<=25000 && lisline[i].Product_sub_Family__c == CPQ_Constants.enterprisePlus))
                        Discount_Tier_Ratio=0.49;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=10000 || (lisline[i].Apttus_QPConfig__Quantity2__c<=50000 && lisline[i].Product_sub_Family__c == CPQ_Constants.enterprisePlus))
                        Discount_Tier_Ratio=0.43;
                        else
                        Discount_Tier_Ratio=0.34;                        
                    }
                    else if(lisline[i].Product_Option_Code__c==CPQ_Constants.BOX_DICOM_CODE || lisline[i].Product_Option_Code__c==CPQ_Constants.boxRelayCodeCode
                        ||lisline[i].Product_Option_Code__c==CPQ_Constants.boxRelayPartialDeploymentCode || lisline[i].Product_Option_Code__c==CPQ_Constants.BOX_GOVERNANCE_CODE){
                        if(lisline[i].Apttus_QPConfig__Quantity2__c<=50)
                        Discount_Tier_Ratio=1;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=100){
                            if(lisline[i].Product_Option_Code__c==CPQ_Constants.BOX_DICOM_CODE || lisline[i].Product_Option_Code__c==CPQ_Constants.boxRelayCodeCode)
                            Discount_Tier_Ratio=1;
                            else
                            Discount_Tier_Ratio=0.96;
                        }
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=250)
                        Discount_Tier_Ratio=0.91;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=500)
                        Discount_Tier_Ratio=0.86;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=1000)
                        Discount_Tier_Ratio=0.8;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=2500)
                        Discount_Tier_Ratio=0.75;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=5000)
                        Discount_Tier_Ratio=0.7;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=10000)
                        Discount_Tier_Ratio=0.64;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=25000)
                        Discount_Tier_Ratio=0.57;
                        else if(lisline[i].Apttus_QPConfig__Quantity2__c<=50000)
                        Discount_Tier_Ratio=0.5;
                        else
                        Discount_Tier_Ratio=0.43;
                    }
                    else 
                    Discount_Tier_Ratio=1;                    

                    //
                    //Start of Changes for BC-1297
                    if(lisLine[i].Approval_Discount_Percentage__c!=null && !(newMap.get(lisLine[i].Apttus_Proposal__Proposal__c).Is_Channel__c)){
                        if(LineItemToBeUpdatedMap.containsKey(lisLine[i].Id)){
                            LineItemToBeUpdatedMap.get(lisLine[i].Id).Tiered_Discount_Percentage__c = 100*(1-((1-(lisLine[i].Approval_Discount_Percentage__c)/100)/Discount_Tier_Ratio));
                        }
                        else{
                            LineItemToBeUpdatedMap.put(lisLine[i].Id,lisLine[i]);
                            LineItemToBeUpdatedMap.get(lisLine[i].Id).Tiered_Discount_Percentage__c = 100*(1-((1-(lisLine[i].Approval_Discount_Percentage__c)/100)/Discount_Tier_Ratio));
                        }
                    }
                    else if(!isIBMPricelist && lisLine[i].Approval_Discount_Percentage__c!=null && (newMap.get(lisLine[i].Apttus_Proposal__Proposal__c).Is_Channel__c)){
                        if(LineItemToBeUpdatedMap.containsKey(lisLine[i].Id)){
                            LineItemToBeUpdatedMap.get(lisLine[i].Id).Tiered_Discount_Percentage__c = lisLine[i].Approval_Discount_Percentage__c;
                        }
                        else{
                            LineItemToBeUpdatedMap.put(lisLine[i].Id,lisLine[i]);
                            LineItemToBeUpdatedMap.get(lisLine[i].Id).Tiered_Discount_Percentage__c = lisLine[i].Approval_Discount_Percentage__c;
                        }
                    }
                    //End of Changes for BC-1297

                    //Added by Anay Bhande: JIRA BC-551 (Set Finalized Proposals to Approval required)
                    if(lisLine[i].Apttus_QPApprov__Approval_Status__c!=CPQ_Constants.APPROVAL_REQUIRED){
                        if(LineItemToBeUpdatedMap.containsKey(lisLine[i].Id)){
                            lisLine[i].Apttus_QPApprov__Approval_Status__c=CPQ_Constants.APPROVAL_REQUIRED;                
                        }
                        else{
                            LineItemToBeUpdatedMap.put(lisLine[i].Id,lisLine[i]);
                            LineItemToBeUpdatedMap.get(lisLine[i].Id).Apttus_QPApprov__Approval_Status__c=CPQ_Constants.APPROVAL_REQUIRED;
                        }
                    }
                    //End of Changes for BC-551


                    //Added by Anay Bhande: JIRA BC-555 
                    if(mapUsers.get(lisLine[i].Apttus_Proposal__Proposal__r.OwnerId).ManagerId!=null){
                        if(LineItemToBeUpdatedMap.containsKey(lisLine[i].Id)){
                            LineItemToBeUpdatedMap.get(lisLine[i].Id).Manager__c=mapUsers.get(lisLine[i].Apttus_Proposal__Proposal__r.OwnerId).ManagerId;           
                        }
                        else{
                            LineItemToBeUpdatedMap.put(lisLine[i].Id,lisLine[i]);
                            LineItemToBeUpdatedMap.get(lisLine[i].Id).Manager__c=mapUsers.get(lisLine[i].Apttus_Proposal__Proposal__r.OwnerId).ManagerId;
                        }
                    }
                    //End of BC-555
                    //BC-3845 start
                    LineItemToBeUpdatedMap.get(lisLine[i].Id).Unit_Price_Per_Payment_Frequency__c = lisLine[i].Incremental_NetUnitPrice__c;
                    //BC-3845 stop

                    Boolean isRenewal = false;
                    if(lisLine[i].Apttus_Proposal__Proposal__r.Quote_Type__c == CPQ_Constants.RENEWAL)
                    isRenewal = true;

                    //setRollupFields
                    if(lisLine[i].Apttus_QPConfig__PriceType__c == CPQ_Constants.RECURRING){
                        Decimal Term =0;
                        Decimal Quantity=0;
                        if(isRenewal)
                        Quantity=lisLine[i].Apttus_QPConfig__Quantity2__c;
                        else
                        Quantity=lisLine[i].Incremental_Quantity__c;
                        if(!LineItemToBeUpdatedMap.containsKey(lisLine[i].Id)){
                            LineItemToBeUpdatedMap.put(lisLine[i].Id,lisLine[i]);
                        }
                        
                        if(isRenewal && lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.PREPAY_FREQUENCY
                        && lisline[i].Apttus_Proposal__Proposal__r.Non_Standard_Term__c!=Null){
                            Term = lisline[i].Apttus_Proposal__Proposal__r.Non_Standard_Term__c;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.MONTHLY_FREQUENCY){
                            Term=1;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.QUARTERLY_FREQUENCY){
                            Term = 3;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.SEMIANNUAL_FREQUENCY){
                            Term = 6;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.ANNUAL_FREQUENCY){
                            Term = 12;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.TWOYEAR_FREQUENCY){
                            Term = 24;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.THREEYEAR_FREQUENCY){
                            Term = 36;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.FOURYEAR_FREQUENCY){
                            Term = 48;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.FIVEYEAR_FREQUENCY){
                            Term = 60;
                        }
                        else{
                            Term = 0;
                        }

                        LineItemToBeUpdatedMap.get(lisLine[i].Id).Amount_Per_payment_Frequency_Number__c = lisLine[i].Incremental_NetUnitPrice__c * Quantity * Term;
                        //BC-3845 start
                        LineItemToBeUpdatedMap.get(lisLine[i].Id).Unit_Price_Per_Payment_Frequency__c = lisLine[i].Incremental_NetUnitPrice__c * Term;
                        //BC-3845 stop
                    }


                    //START:JIRA: #BC-1164 & #BC-1010 To calculate Seat Sold and Total Contract Entitlements - Added by Shikha Dave
                    if(lisLine[i].Apttus_QPConfig__LineType__c==CPQ_Constants.OPTION && lisLine[i].Apttus_QPConfig__OptionId__r.Product_Group__c != NULL && lisLine[i].Apttus_QPConfig__OptionId__r.Product_Group__c.contains(CPQ_constants.CORE_LICENSES)){

                      if(newMap.get(lisLine[i].Apttus_Proposal__Proposal__c).Quote_Type__c == CPQ_constants.NEWVAR || newMap.get(lisLine[i].Apttus_Proposal__Proposal__c).Quote_Type__c == CPQ_constants.UPSELL
                        || newMap.get(lisLine[i].Apttus_Proposal__Proposal__c).Quote_Type__c == CPQ_constants.RENEWAL){
                          Total_Contract_Entitlements = lisLine[i].Apttus_QPConfig__Quantity2__c == NULL ? 0:lisLine[i].Apttus_QPConfig__Quantity2__c;
                      }else if(newMap.get(lisLine[i].Apttus_Proposal__Proposal__c).Quote_Type__c == CPQ_constants.RESTART && lisLine[i].Apttus_QPConfig__LineStatus__c != CPQ_constants.CANCELLED){
                          Total_Contract_Entitlements = lisLine[i].Apttus_QPConfig__Quantity2__c == NULL ? 0:lisLine[i].Apttus_QPConfig__Quantity2__c;
                      }else if(newMap.get(lisLine[i].Apttus_Proposal__Proposal__c).Quote_Type__c == CPQ_constants.CANCELLATION && lisLine[i].Apttus_QPConfig__LineStatus__c == CPQ_constants.CANCELLED){
                          Total_Contract_Entitlements = lisLine[i].Apttus_QPConfig__Quantity2__c == NULL ? 0:lisLine[i].Apttus_QPConfig__Quantity2__c;
                      }
                      //System.debug('Total_Contract_Entitlements: '+Total_Contract_Entitlements);                    
                      ProposalToTotal_Contract_EntitlementsMap.put(lisLine[i].Apttus_Proposal__Proposal__c,Total_Contract_Entitlements);
                    }
                    //END:JIRA: #BC-1164 & #BC-1010

                    //added by mitul for adding Annual_Recurring_Revenue__c and Non_Recurring_Revenue__c, BC-1614
                    if(lisLine[i].Apttus_QPConfig__PriceType__c != NULL && lisLine[i].Apttus_QPConfig__PriceType__c != CPQ_constants.RECURRING 
                      && lisLine[i].Direct_Net_ARR_NRR__c != NULL){
                            nonRecNRR = nonRecNRR + lisLine[i].Direct_Net_ARR_NRR__c;
                            ProposalToNonRecNRRMap.put(lisLine[i].Apttus_Proposal__Proposal__c,nonRecNRR.setScale(5));
                        
                    }

                    //added by mitul for adding Annual_Recurring_Revenue__c and Non_Recurring_Revenue__c, BC-1614
                    if(lisLine[i].Apttus_QPConfig__PriceType__c != NULL && lisLine[i].Apttus_QPConfig__LineType__c != NULL 
                      && lisLine[i].Apttus_QPConfig__PriceType__c == CPQ_constants.RECURRING && (lisLine[i].Apttus_QPConfig__LineType__c==CPQ_Constants.OPTION || lisLine[i].Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c==CPQ_Constants.STANDALONE)){
                        
                        renewalAmount = ProposalToRenewalAmountMap.get(lisLine[i].Apttus_Proposal__Proposal__c);
                        if(lisLine[i].Apttus_QPConfig__LineStatus__c == CPQ_Constants.RENEWED && lisLine[i].Delta_ARR_x__c != null){
                            renewalAmount = renewalAmount  + lisLine[i].Direct_Net_ARR_NRR__c;
                        }else if(lisLine[i].Apttus_QPConfig__LineStatus__c != CPQ_Constants.RENEWED && lisLine[i].Incremental_ARR_NRR__c != null){
                             renewalAmount = renewalAmount  + lisLine[i].Direct_Net_ARR_NRR__c;
                        }
                        ProposalToRenewalAmountMap.put(lisLine[i].Apttus_Proposal__Proposal__c,renewalAmount.setScale(5));
                    }

                    if((lisLine[i].Apttus_QPConfig__LineStatus__c==CPQ_Constants.AMENDED || lisLine[i].Apttus_QPConfig__LineStatus__c==CPQ_Constants.RENEWED || lisLine[i].Apttus_QPConfig__LineStatus__c==CPQ_Constants.NEWVAR || lisLine[i].Apttus_QPConfig__LineStatus__c==CPQ_Constants.CANCELLED)){
                        if(( lisLine[i].Apttus_QPConfig__LineType__c==CPQ_Constants.OPTION  || 
                          (lisLine[i].Apttus_QPConfig__LineType__c!=CPQ_Constants.OPTION && lisLine[i].Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c==CPQ_Constants.STANDALONE)) &&  lisLine[i].Apttus_QPConfig__LineStatus__c!=CPQ_Constants.CANCELLED){
                            Total_Rec=ProposalToTotalRecMap.get(lisLine[i].Apttus_Proposal__Proposal__c);
                            TCVRec=ProposalToTCVRecMap.get(lisLine[i].Apttus_Proposal__Proposal__c);
                            TCVNonRec=ProposalToTCVNonRecMap.get(lisLine[i].Apttus_Proposal__Proposal__c);

                            if(lisLine[i].Apttus_QPConfig__PriceType__c==CPQ_Constants.RECURRING && lisLine[i].Amount_Per_payment_Frequency__c!=NULL)
                            Total_Rec=Total_Rec + lisLine[i].Amount_Per_payment_Frequency__c;
                            ProposalToTotalRecMap.put(lisLine[i].Apttus_Proposal__Proposal__c,Total_Rec);

                            if(lisLine[i].Apttus_QPConfig__PriceType__c==CPQ_Constants.RECURRING && lisLine[i].Incremental_Net_Price__c!=NULL){
                                if(lisLine[i].Apttus_Proposal__Proposal__r.Quote_Type__c == CPQ_constants.RESTART && lisLine[i].Apttus_QPConfig__LineStatus__c != CPQ_constants.CANCELLED){
                                    TCVRec=TCVRec + lisLine[i].Incremental_Net_Price__c;
                                    ProposalToTCVRecMap.put(lisLine[i].Apttus_Proposal__Proposal__c,TCVRec);
                                }else if(lisLine[i].Apttus_Proposal__Proposal__r.Quote_Type__c != CPQ_constants.RESTART){
                                    TCVRec=TCVRec + lisLine[i].Incremental_Net_Price__c;
                                    ProposalToTCVRecMap.put(lisLine[i].Apttus_Proposal__Proposal__c,TCVRec);
                                }
                            }
                            if(lisLine[i].Apttus_QPConfig__PriceType__c != NULL && lisLine[i].Apttus_QPConfig__PriceType__c!=CPQ_Constants.RECURRING && lisLine[i].Incremental_Net_Price__c!=NULL){
                                if(lisLine[i].Apttus_Proposal__Proposal__r.Quote_Type__c == CPQ_constants.RESTART && lisLine[i].Apttus_QPConfig__LineStatus__c != CPQ_constants.CANCELLED){
                                    TCVNonRec=TCVNonRec + lisLine[i].Incremental_Net_Price__c;
                                    ProposalToTCVNonRecMap.put(lisLine[i].Apttus_Proposal__Proposal__c,TCVNonRec);
                                }else if(lisLine[i].Apttus_Proposal__Proposal__r.Quote_Type__c != CPQ_constants.RESTART){
                                    TCVNonRec=TCVNonRec + lisLine[i].Incremental_Net_Price__c;
                                    ProposalToTCVNonRecMap.put(lisLine[i].Apttus_Proposal__Proposal__c,TCVNonRec);
                                }
                            }
                            
                        }
                    }

                    //Start BC-4079: Populate Net support service based on Delta ARR/Direct Net ARR NRR - Changed by Shikha Dave
                    if(lisLine[i].Apttus_QPConfig__LineType__c==CPQ_Constants.OPTION && lisLine[i].Apttus_QPConfig__OptionId__r.Product_Group__c!=null && lisLine[i].Apttus_QPConfig__OptionId__r.Product_Group__c.contains(CPQ_constants.SERVICES_SUPPORT)){
                                            
                        if(lisLine[i].Apttus_QPConfig__LineStatus__c!=CPQ_Constants.EXISTING && newMap.get(lisLine[i].Apttus_Proposal__Proposal__c).Is_Channel__c){
                            
                            Gross_Support_Services_Amount = ProposalToGrossSupportServiceAmount.get(lisLine[i].Apttus_Proposal__Proposal__c);
                            if((lisLine[i].Apttus_QPConfig__LineStatus__c == CPQ_Constants.RENEWED) && lisLine[i].Delta_ARR_x__c != null){
                                Gross_Support_Services_Amount += lisLine[i].Delta_ARR_x__c * (-1);
                            }else if(lisLine[i].Apttus_QPConfig__LineStatus__c != CPQ_Constants.RENEWED && lisLine[i].Gross_ARR_NRR__c != null){
                                Gross_Support_Services_Amount += lisLine[i].Gross_ARR_NRR__c;
                            }
                            ProposalToGrossSupportServiceAmount.put(lisLine[i].Apttus_Proposal__Proposal__c,Gross_Support_Services_Amount);
                        }
                    //End BC-4079

                        if(!lisLine[i].Apttus_QPConfig__OptionId__r.Name.contains(CPQ_Constants.PRODUCT_GROUP_PLATFORM)){
                            if(newMap.get(lisLine[i].Apttus_Proposal__Proposal__c).Quote_Type__c != CPQ_Constants.CANCELLED && lisLine[i].Apttus_QPConfig__LineStatus__c!=CPQ_Constants.CANCELLED )
                                ContainsPremierandPlatinumServices.put(lisLine[i].Apttus_Proposal__Proposal__c,lisLine[i].Apttus_QPConfig__OptionId__r.Name);
                            else if(newMap.get(lisLine[i].Apttus_Proposal__Proposal__c).Quote_Type__c == CPQ_Constants.CANCELLED && lisLine[i].Apttus_QPConfig__LineStatus__c==CPQ_Constants.CANCELLED )
                                ContainsPremierandPlatinumServices.put(lisLine[i].Apttus_Proposal__Proposal__c,lisLine[i].Apttus_QPConfig__OptionId__r.Name);
                        }
                    }
                   
                    if(lisLine[i].Apttus_QPConfig__LineType__c==CPQ_Constants.LINE_TYPE_PRODUCT_SERVICE && (lisLine[i].Apttus_Proposal__Product__r.Product_Grouping__c==CPQ_Constants.PRODUCT_GROUP_CORE || 
                        lisLine[i].Apttus_Proposal__Product__r.Product_Grouping__c==CPQ_Constants.PRODUCT_GROUP_PLATFORM) &&(newMap.get(lisLine[i].Apttus_Proposal__Proposal__c).Quote_Type__c==CPQ_Constants.NEWVAR || 
                        newMap.get(lisLine[i].Apttus_Proposal__Proposal__c).Quote_Type__c==CPQ_Constants.RENEWAL || newMap.get(lisLine[i].Apttus_Proposal__Proposal__c).Quote_Type__c==CPQ_Constants.RESTART) && 
                        (lisLine[i].Apttus_QPConfig__LineStatus__c==CPQ_Constants.RENEWED || lisLine[i].Apttus_QPConfig__LineStatus__c==CPQ_Constants.NEWVAR)){
                                
                                if(newMap.get(lisLine[i].Apttus_Proposal__Proposal__c).Contract_Term__c<12)
                                {
                                    if(lisLine[i].Apttus_Proposal__Product__r.ProductCode.contains(CPQ_Constants.businessPlusProductCode))
                                        QuoteAccountTypeSold.put(lisLine[i].Apttus_Proposal__Proposal__c,CPQ_Constants.BUSINESS_PLUS_SHORT_TERM);
                                    else if(lisLine[i].Apttus_Proposal__Product__r.ProductCode.contains(CPQ_Constants.eliteProductCode))
                                        QuoteAccountTypeSold.put(lisLine[i].Apttus_Proposal__Proposal__c,CPQ_Constants.ELITE_SHORT_TERM);
                                    else if(lisLine[i].Apttus_Proposal__Product__r.ProductCode.contains(CPQ_Constants.enterpriseProductCode) || lisLine[i].Apttus_Proposal__Product__r.ProductCode.contains(CPQ_Constants.platformEnterpriseCode))
                                        QuoteAccountTypeSold.put(lisLine[i].Apttus_Proposal__Proposal__c,CPQ_Constants.ENTERPRISE_SHORT_TERM);
                                    else if(lisLine[i].Apttus_Proposal__Product__r.ProductCode.contains(CPQ_Constants.businessProductCode))
                                        QuoteAccountTypeSold.put(lisLine[i].Apttus_Proposal__Proposal__c,CPQ_Constants.BUSINESS_SHORT_TERM);
                                }
                                else if(lisLine[i].Has_Zones__c)
                                {
                                    if(lisLine[i].Apttus_Proposal__Product__r.ProductCode.contains(CPQ_Constants.businessPlusProductCode))
                                        QuoteAccountTypeSold.put(lisLine[i].Apttus_Proposal__Proposal__c,CPQ_Constants.BUSINESS_PLUS_WITH_ZONES);
                                    else if(lisLine[i].Apttus_Proposal__Product__r.ProductCode.contains(CPQ_Constants.eliteProductCode))
                                        QuoteAccountTypeSold.put(lisLine[i].Apttus_Proposal__Proposal__c,CPQ_Constants.ELITE_WITH_ZONES);
                                    else if(lisLine[i].Apttus_Proposal__Product__r.ProductCode.contains(CPQ_Constants.enterpriseProductCode) || lisLine[i].Apttus_Proposal__Product__r.ProductCode.contains(CPQ_Constants.platformEnterpriseCode))
                                        QuoteAccountTypeSold.put(lisLine[i].Apttus_Proposal__Proposal__c,CPQ_Constants.ENTERPRISE_WITH_ZONES);
                                }
                                else
                                {
                                    if(lisLine[i].Apttus_Proposal__Product__r.ProductCode.contains(CPQ_Constants.businessPlusProductCode))
                                        QuoteAccountTypeSold.put(lisLine[i].Apttus_Proposal__Proposal__c,CPQ_Constants.BUSINESS_PLUS_ACCOUNT_TYPE_SOLD);
                                    else if(lisLine[i].Apttus_Proposal__Product__r.ProductCode.contains(CPQ_Constants.eliteProductCode))
                                        QuoteAccountTypeSold.put(lisLine[i].Apttus_Proposal__Proposal__c,CPQ_Constants.ELITE_ACCOUNT_TYPE_SOLD);
                                    else if(lisLine[i].Apttus_Proposal__Product__r.ProductCode.contains(CPQ_Constants.enterpriseProductCode) || lisLine[i].Apttus_Proposal__Product__r.ProductCode.contains(CPQ_Constants.platformEnterpriseCode))
                                        QuoteAccountTypeSold.put(lisLine[i].Apttus_Proposal__Proposal__c,CPQ_Constants.ENTERPRISE_ACCOUNT_TYPE_SOLD);
                                    else if(lisLine[i].Apttus_Proposal__Product__r.ProductCode.contains(CPQ_Constants.businessProductCode))
                                        QuoteAccountTypeSold.put(lisLine[i].Apttus_Proposal__Proposal__c,CPQ_Constants.BUSINESS_ACCOUNT_TYPE_SOLD);
                                }
                    }

                    //end of setRollupFields
                }
                      
                update LineItemToBeUpdatedMap.values();

                for( Id pId : setFinalizedProposalIds ){

                    Apttus_Proposal__Proposal__c proposal = newMap.get( pId );

                    //Added for BC-556
                    proposal.Approval_Line_Level_Rejection__c=null;

                    //Added by Anay Bhande: JIRA BC-555 
                    if(mapUsers.get(proposal.OwnerId).ManagerId!=null)
                    proposal.Manager__c=mapUsers.get(proposal.OwnerId).ManagerId;

                    //Added by Anay Bhande: JIRA BC-551 (Set Finalized Proposals to Approval required)
                    if(proposal.Apttus_Proposal__Approval_Stage__c!=CPQ_Constants.APPROVAL_REQUIRED){
                      proposal.Apttus_QPApprov__Approval_Status__c=CPQ_Constants.APPROVAL_REQUIRED;
                      proposal.Apttus_Proposal__Approval_Stage__c=CPQ_Constants.APPROVAL_REQUIRED;
                    }

                    //setRollupFields
                    proposal.Total_Rec_Am_Per_Payment_Frequency__c = ProposalToTotalRecMap.get(pId);
                    proposal.Total_Contract_Value_Non_Recurring__c = ProposalToTCVNonRecMap.get(pId);
                    proposal.Total_Contract_Value_TCV_Recurring__c = ProposalToTCVRecMap.get(pId);
                    //added by mitul for changing the field to number
                    proposal.Total_Contract_Entitlements__c = ProposalToTotal_Contract_EntitlementsMap.get(pId);
                    //added by mitul for changing the ARR and NRR to Currency
                    proposal.Non_Recurring_Revenue__c = ProposalToNonRecNRRMap.get(pId);

                    if(QuoteAccountTypeSold.get(pId)<>null)
                        proposal.Account_Type_Sold__c = QuoteAccountTypeSold.get(pId);
                    else if(proposal.Quote_Type__c <> CPQ_Constants.UPSELL)
                        proposal.Account_Type_Sold__c = null;

                    if(proposal.Is_Channel__c){
                        proposal.Gross_Support_Services_Amount__c = ProposalToGrossSupportServiceAmount.get(pId);
                    }


                    if(ContainsPremierandPlatinumServices.get(pId)<>null)
                    {
                        if(ContainsPremierandPlatinumServices.get(pId).contains(CPQ_Constants.premierServices))
                            proposal.Support_Services__c = CPQ_Constants.premierServices;
                        else if(ContainsPremierandPlatinumServices.get(pId).contains(CPQ_Constants.platinumServices))
                            proposal.Support_Services__c = CPQ_Constants.platinumServices;
                        else if(ContainsPremierandPlatinumServices.get(pId).contains(CPQ_Constants.BUSINESS))
                            proposal.Support_Services__c = CPQ_Constants.BUSINESS;

                    }

                     //JIRA 910
                    proposal.Is_zero_dollar_quote__c = CPQ_constants.setFalse;

                    if( proposal.Total_Contract_Value_Non_Recurring__c == 0.0 && proposal.Total_Contract_Value_TCV_Recurring__c == 0.0 )
                    {
                      //System.debug('inside iz zero dollar quote');
                       proposal.Is_zero_dollar_quote__c = CPQ_constants.setTrue;
                    }
                    //END JIRA 910                    
                }
            }
            catch(Exception ex)  {
                SystemMessage.log( 'CPQ_ProposalTriggerHelper method updateProposalLineItems failed', ex );

                System.debug(ex.getMessage());
                System.debug('ex.getLineNumber()' + ex.getLineNumber());
            }
        }
    }

    //BC-3845 start
    public static void updateProposalLineItemsBeforeApprovals(Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap){

        Map<Id,Apttus_Proposal__Proposal_Line_Item__c> LineItemToBeUpdatedMap = new Map<Id,Apttus_Proposal__Proposal_Line_Item__c>(); 

        set<Id> setApprovalProposalIds = new set<Id>();
        for(Apttus_Proposal__Proposal__c proposal : newMap.values()) {
            if((oldMap.get(proposal.Id).Apttus_QPApprov__Approval_Status__c==CPQ_Constants.CANCELLED
                ||oldMap.get(proposal.Id).Apttus_QPApprov__Approval_Status__c==CPQ_Constants.REJECTED
                || oldMap.get(proposal.Id).Apttus_QPApprov__Approval_Status__c==CPQ_Constants.APPROVAL_REQUIRED)
                && (proposal.Apttus_QPApprov__Approval_Status__c==CPQ_Constants.APPROVED
                    ||proposal.Apttus_QPApprov__Approval_Status__c==CPQ_Constants.PENDING_APPROVAL)){
                    setApprovalProposalIds.add(proposal.Id);
            }
        } 
        if(setApprovalProposalIds.size() > 0) {
            List<Apttus_Proposal__Proposal_Line_Item__c> lisLine = [Select id, Apttus_Proposal__Proposal__c, Apttus_QPApprov__Approval_Status__c,
                                                                            Apttus_QPConfig__LineType__c, Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c, Incremental_NetUnitPrice__c,Apttus_QPConfig__Quantity2__c,
                                                                            Apttus_QPConfig__PriceType__c, Amount_Per_payment_Frequency__c, Apttus_QPConfig__LineStatus__c, Apttus_Proposal__Proposal__r.Payment_Frequency__c, 
                                                                            Suite_line_on_suite_bundle__c, Incremental_Quantity__c, Incremental_Net_Price__c, Apttus_Proposal__Proposal__r.Non_Standard_Term__c,
                                                                            Apttus_Proposal__Proposal__r.Quote_Type__c, Apttus_QPConfig__SellingTerm__c  from Apttus_Proposal__Proposal_Line_Item__c 
                                                                    where Apttus_Proposal__Proposal__c in :setApprovalProposalIds];
            try{
                Map<Id,Double> ProposalToTotalRecMap = new Map<Id,Double>();   

                Double Total_Rec;

                for(Id pId:setApprovalProposalIds){
                    ProposalToTotalRecMap.put(pId,0);
                }
                //End of setRollupFields
                                
                for(Integer i=0;i<lisLine.size();i++){
                    Boolean isRenewal = false;
                    if(lisLine[i].Apttus_Proposal__Proposal__r.Quote_Type__c == CPQ_Constants.RENEWAL)
                    isRenewal = true;

                    if((lisLine[i].Apttus_QPConfig__LineStatus__c==CPQ_Constants.AMENDED || lisLine[i].Apttus_QPConfig__LineStatus__c==CPQ_Constants.RENEWED || lisLine[i].Apttus_QPConfig__LineStatus__c==CPQ_Constants.NEWVAR || lisLine[i].Apttus_QPConfig__LineStatus__c==CPQ_Constants.CANCELLED)){
                        if(( lisLine[i].Apttus_QPConfig__LineType__c==CPQ_Constants.OPTION  || 
                          (lisLine[i].Apttus_QPConfig__LineType__c!=CPQ_Constants.OPTION && lisLine[i].Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c==CPQ_Constants.STANDALONE)) &&  lisLine[i].Apttus_QPConfig__LineStatus__c!=CPQ_Constants.CANCELLED){
                            Total_Rec=ProposalToTotalRecMap.get(lisLine[i].Apttus_Proposal__Proposal__c);

                            if(lisLine[i].Apttus_QPConfig__PriceType__c==CPQ_Constants.RECURRING && lisLine[i].Amount_Per_payment_Frequency__c!=NULL){
                                Total_Rec=Total_Rec + lisLine[i].Amount_Per_payment_Frequency__c;
                                ProposalToTotalRecMap.put(lisLine[i].Apttus_Proposal__Proposal__c,Total_Rec);
                            }
                        }
                    }
                    
                    //setRollupFields
                    if(lisLine[i].Apttus_QPConfig__PriceType__c == CPQ_Constants.RECURRING){
                        Decimal Term =0;
                        Decimal Quantity=0;
                        if(isRenewal)
                        Quantity=lisLine[i].Apttus_QPConfig__Quantity2__c;
                        else
                        Quantity=lisLine[i].Incremental_Quantity__c;
                        if(!LineItemToBeUpdatedMap.containsKey(lisLine[i].Id)){
                            LineItemToBeUpdatedMap.put(lisLine[i].Id,lisLine[i]);
                        }
                        
                        if(isRenewal && lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.PREPAY_FREQUENCY
                        && lisline[i].Apttus_Proposal__Proposal__r.Non_Standard_Term__c!=Null){
                            Term = lisline[i].Apttus_Proposal__Proposal__r.Non_Standard_Term__c;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.MONTHLY_FREQUENCY){
                            Term=1;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.QUARTERLY_FREQUENCY){
                            Term = 3;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.SEMIANNUAL_FREQUENCY){
                            Term = 6;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.ANNUAL_FREQUENCY){
                            Term = 12;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.TWOYEAR_FREQUENCY){
                            Term = 24;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.THREEYEAR_FREQUENCY){
                            Term = 36;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.FOURYEAR_FREQUENCY){
                            Term = 48;
                        }
                        else if(lisLine[i].Apttus_Proposal__Proposal__r.Payment_Frequency__c == CPQ_Constants.FIVEYEAR_FREQUENCY){
                            Term = 60;
                        }
                        else{
                            Term = 0;
                        }
                        LineItemToBeUpdatedMap.get(lisLine[i].Id).Amount_Per_payment_Frequency_Number__c = lisLine[i].Incremental_NetUnitPrice__c * Quantity * Term;
                        //BC-3845 start
                        LineItemToBeUpdatedMap.get(lisLine[i].Id).Unit_Price_Per_Payment_Frequency__c = lisLine[i].Incremental_NetUnitPrice__c * Term;
                        //BC-3845 stop
                    }
                }
                update LineItemToBeUpdatedMap.values();

                for(Id pId:setApprovalProposalIds){
                    newMap.get(pId).Total_Rec_Am_Per_Payment_Frequency__c = ProposalToTotalRecMap.get(pId);
                }
            }
            catch(Exception ex)  {
                SystemMessage.log( 'CPQ_ProposalTriggerHelper method updateProposalLineItemsBeforeApprovals failed', ex );

                System.debug(ex.getMessage());
                System.debug('ex.getLineNumber()' + ex.getLineNumber());
            }
        }
    }
    //BC-3845 end

    //BC-3960 and BC-3813
    public static void setConsultingApproval(Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap) {
        set<Id> setFinalizedProposalIds = new set<Id>();
        for(Apttus_Proposal__Proposal__c proposal : newMap.values()) {
            if(((oldMap.get(proposal.Id)).Apttus_QPConfig__ConfigurationFinalizedDate__c == null
                && proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != null)
               || 
               (oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != null
                && oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c) ) {
                setFinalizedProposalIds.add(proposal.Id);
            }
        }            
        
        if(setFinalizedProposalIds.size() > 0) {
            try {
                List<Apttus_Config2__AppliedRuleActionInfo__c> lisActions= [Select Apttus_Config2__ConstraintRuleActionId__r.Apttus_Config2__ConstraintRuleId__r.Name, Apttus_Config2__ConstraintRuleActionId__r.Name, 
                                                                        Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c, Apttus_Config2__ConstraintRuleActionId__r.Apttus_Config2__ProductId__r.ProductCode, Apttus_Config2__ConstraintRuleActionId__r.Apttus_Config2__ProductId__r.Product_Grouping__c  from Apttus_Config2__AppliedRuleActionInfo__c 
                                                                        where (Apttus_Config2__Ignored__c = true or Apttus_Config2__Pending__c = true) and Apttus_Config2__ConfigurationId__c in :([Select Id from Apttus_Config2__ProductConfiguration__c 
                                                                        where Apttus_QPConfig__Proposald__c in :setFinalizedProposalIds and Apttus_Config2__Status__c=:CPQ_Constants.FINALIZED])];
                                                                        
                List<Apttus_Config2__ProductConfiguration__c> lisConfig= [Select Id, Apttus_Config2__Status__c, Removed_Products__c, Apttus_QPConfig__Proposald__c, Quote_Type__c from Apttus_Config2__ProductConfiguration__c 
                                                                        where Apttus_QPConfig__Proposald__c in :setFinalizedProposalIds and Apttus_Config2__Status__c=:CPQ_Constants.FINALIZED];

                for(Apttus_Proposal__Proposal__c proposal : newMap.values()){
                    proposal.Premier_Platinum_Services_Removed__c=false;
                    proposal.Consulting_Product_Removed__c=false;
                }

                for(Apttus_Config2__ProductConfiguration__c conf:lisConfig){
                    for(String code:CPQ_Constants.CONSULTING_PRODUCTCODES){
                        if(conf.Removed_Products__c != NULL && conf.Removed_Products__c.contains(code)){
                            newMap.get(conf.Apttus_QPConfig__Proposald__c).Consulting_Product_Removed__c=true;
                            break;
                        }
                    }
                    if(conf.Quote_Type__c!=CPQ_Constants.RENEWAL)
                    for(String code:CPQ_Constants.NON_RENEWAL_CONSULTING_PRODUCTCODES){
                        if(conf.Removed_Products__c != NULL && conf.Removed_Products__c.contains(code)){
                            newMap.get(conf.Apttus_QPConfig__Proposald__c).Consulting_Product_Removed__c=true;
                            break;
                        }
                    }
                }
                
                //System.debug('lisActions'+lisActions);
                for(Apttus_Config2__AppliedRuleActionInfo__c act:lisActions){
                    //System.debug('act.Apttus_Config2__ConstraintRuleActionId__r.Name' + act.Apttus_Config2__ConstraintRuleActionId__r.Name);
                    //System.debug(act.Apttus_Config2__ConstraintRuleActionId__r.Apttus_Config2__ProductId__r.Product_Grouping__c);
                    if(act.Apttus_Config2__ConstraintRuleActionId__r.Name.containsIgnoreCase(CPQ_Constants.WORD_INCLUDE)
                        || act.Apttus_Config2__ConstraintRuleActionId__r.Apttus_Config2__ConstraintRuleId__r.Name.containsIgnoreCase(CPQ_Constants.WORD_INCLUDE)){
                        if((act.Apttus_Config2__ConstraintRuleActionId__r.Apttus_Config2__ProductId__r.ProductCode == CPQ_Constants.platformPremierServiceCode
                            && newMap.get(act.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c).Count_of_Platform_Platinum_Services__c == 0
                            && newMap.get(act.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c).Count_of_Platform_Premier_Services__c == 0) 
                        || 
                            (act.Apttus_Config2__ConstraintRuleActionId__r.Apttus_Config2__ProductId__r.ProductCode == CPQ_Constants.premierServiceCode
                            && newMap.get(act.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c).Count_of_Platinum_Services__c == 0
                            && newMap.get(act.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c).Count_of_Premier_Services__c == 0)
                        ||
                            (act.Apttus_Config2__ConstraintRuleActionId__r.Name.containsIgnoreCase(CPQ_Constants.PREMIER_SERVICES) 
                            || act.Apttus_Config2__ConstraintRuleActionId__r.Apttus_Config2__ConstraintRuleId__r.Name.containsIgnoreCase(CPQ_Constants.PREMIER_SERVICES))){
                            newMap.get(act.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c).Premier_Platinum_Services_Removed__c=true;
                        }
                    }
                }
            }
            catch(Exception ex)  {
                SystemMessage.log( 'CPQ_ProposalTriggerHelper method setConsultingApproval failed', ex );                
                System.debug(ex.getMessage());
            }    
        }        
    }

    //Update Opportunity fields on finalization of cart from the Quote, JIRA: #BC-527 - Added by Shikha Dave
    public static void updateOpptyOnProposalUpdate(Map<Id,Apttus_Proposal__Proposal__c> mapOldProposal,Map<Id,Apttus_Proposal__Proposal__c> mapNewProposal){

        //System.debug('updateOpptyOnProposalUpdate');
        Apttus_Proposal__Proposal__c mNew;
        Set<id> setNewOpptyId = New Set<id>();
        Map<id,Apttus_Proposal__Proposal__c> opptyIDproposalIDMap = new Map <id,Apttus_Proposal__Proposal__c>();
        Set<id> setNewPropId = mapNewProposal.keySet();
        List<Opportunity> listOpportunities = new List<Opportunity>();
        Boolean isPrimary = false;
        Boolean syncWithOpportunityHeader = true;
        Set<String> setStages = new Set<String>{CPQ_Constants.CLOSED_WON, CPQ_Constants.CLOSED_LOST, CPQ_Constants.ADJUSTMENT, CPQ_Constants.BOUNTY, CPQ_Constants.CANCELLATION_CHURN};

        if(mapOldProposal.size() == mapNewProposal.size()) {
            for(Apttus_Proposal__Proposal__c mOld: mapOldProposal.values()){
                mNew=mapNewProposal.get(mOld.Id);
                isPrimary = false;
                syncWithOpportunityHeader = true;
                if(mOld.Apttus_Proposal__Approval_Stage__c == CPQ_Constants.BOX_PROPOSAL_APPROVAL_FULLY_SIGNED ||
                    mOld.Apttus_Proposal__Approval_Stage__c == CPQ_Constants.BOX_PROPOSAL_APPROVAL_ACCEPTED ||
                    mNew.Apttus_Proposal__Approval_Stage__c == CPQ_Constants.BOX_PROPOSAL_APPROVAL_ACCEPTED){
                    syncWithOpportunityHeader = false;
                }
                //if(mNew.Apttus_Proposal__Primary__c == true && mNew.Apttus_Proposal__Primary__c != mOld.Apttus_Proposal__Primary__c ){
                if((mNew.Apttus_Proposal__Primary__c == true && mOld.Apttus_Proposal__Primary__c==false)  || (mNew.Apttus_Proposal__Primary__c==true && mOld.Apttus_Proposal__Primary__c==true) ){
                    isPrimary = true;
                }

                //if(mOld.Apttus_QPConfig__ConfigurationFinalizedDate__c != mNew.Apttus_QPConfig__ConfigurationFinalizedDate__c || isPrimary) {
                system.debug('***IsPrimary='+isPrimary);
                if(isPrimary && syncWithOpportunityHeader) {
                    setNewOpptyId.add(mNew.Apttus_Proposal__Opportunity__c);
                    opptyIDproposalIDMap.put(mNew.Apttus_Proposal__Opportunity__c,mNew);
                }
                
                if(syncWithOpportunityHeader && (mOld.Contract_Term__c <> mNew.Contract_Term__c || mOld.Payment_Method__c <> mNew.Payment_Method__c || mOld.Overage_Type__c <> mNew.Overage_Type__c || 
                    mOld.Number_of_Licenses__c <> mNew.Number_of_Licenses__c || mOld.Overage_Start_Date__c <> mNew.Overage_Start_Date__c || mOld.Overage_End_Date__c <>mNew.Overage_End_Date__c || 
                    mOld.Overage_Quantity__c <> mapNewProposal.get(mOld.Id).Overage_Quantity__c /*|| mOld.Box_Enterprise_ID__c <> mNew.Box_Enterprise_ID__c*/ || mOld.Payment_Term_Backend__c <> mNew.Payment_Term_Backend__c || isPrimary)) {
                    opportunity oppSO = new opportunity();
                    oppSO.Id = mNew.Apttus_Proposal__Opportunity__c;
                    oppSO.Payment_Term__c = mNew.Quote_Type__c <> CPQ_constants.UPSELL && mNew.Quote_Type__c <> CPQ_constants.CANCELLATION?mNew.Contract_Term__c:mNew.EID_Term__c;
                    oppSO.Payment_Method__c = mNew.Payment_Method__c;
                    oppSO.Overage_Type__c = mNew.Overage_Type__c;
                    oppSO.Number_of_Licenses__c = mNew.Number_of_Licenses__c;
                    oppSO.Overage_Start_Date__c = mNew.Overage_Start_Date__c;
                    oppSO.Overage_End_Date__c = mNew.Overage_End_Date__c;
                    oppSO.Overage_Expiration_Date__c = mNew.Overage_End_Date__c;
                    oppSO.Overage_Quantity__c = mNew.Overage_Quantity__c;
                    //oppSO.Box_Enterprise_ID__c = mNew.Box_Enterprise_ID__c; //as per business process no need to sync from quote to oppty, it will copy from opty to quote
                    oppSO.Fee_Frequency__c = mNew.Payment_Term_Backend__c;
                    listOpportunities.add(oppSO);
                }
            }
        }

        if ( !setNewOpptyId.isEmpty() ) {
            listOpportunities = [ SELECT Id, Subscription_Term_End_Date__c ,Overage_Type__c, Number_of_Licenses__c, Annual_Recurring_Revenue__c, Non_Recurring_Revenue__c,
                                         Total_Contract_Entitlements__c, Total_Contract_Value_TCV__c, Total_Contract_Value_Non_Recurring__c, 
                                         Platform_ARR__c,  Box_Consulting__c, Relay_ARR__c, Governance_ARR__c, Keysafe_ARR__c, Box_Seat_ARR__c, 
                                         Platform_Seats__c, Platform_BC_NRR__c,  Channel_NRR__c, GxP_ARR__c, Overage_Start_Date__c, 
                                         Overage_End_Date__c, Overage_Expiration_Date__c, Overage_Quantity__c,  Has_Keysafe_and_Services__c,
                                         Pre_Renewal_Seats_Sold__c,Pre_Renewal_Account_Type_Sold__c,Pre_Renewal_Contract_Term__c,Support_Services__c,
                                         Net_Support_Services_Amount__c,Gross_Support_Services_Amount__c,Fee_Frequency__c,Payment_Term__c,
                                         Pre_Renewal_Renewal_Amount__c,Renewal_Amount__c,Forecasted_Renewal_Amount__c, Renewal_Date_Renewals__c,Seats_Sold__c,Payment_Method__c,Channel_Amount__c,
                                         Is_Channel__c, Auto_renew_removed__c,True_Up_Frequency__c 
                                  FROM  Opportunity 
                                  WHERE Id IN : setNewOpptyId 
                                  AND StageName NOT IN :setStages]; 
        }

        if ( !listOpportunities.isEmpty() ) {
            // sync proposals to opportunities
            CPQ_ProposalSyncService.syncToOpps( listOpportunities, opptyIDproposalIDMap );
        }

        try {
            if ( listOpportunities.size() > 0 && CPQ_Constants.IS_OPP_SYNC_ENABLED ) {
                update listOpportunities;
            }
        }
        catch( Exception ex ) {
            SystemMessage.log( 'CPQ_ProposalTriggerHelper method updateOpptyOnProposalUpdate failed', ex ); 
            System.debug('Exception in updateOpptyOnProposalUpdate on CPQ_ProposalTriggerHelper : ' + ex.getMessage());
        }
    }

    //Restrict user to create Quote for restricted countries, JIRA: #BC-805 - Added by Shikha Dave Bug: #3067
    public static void restrictQuoteCreationOnCountry(List<Apttus_Proposal__Proposal__c> listNewProposal){
      
      List<Territory_Country__c > listTerritoryCountry = new List<Territory_Country__c > ();
      Set<Id> setContact = new Set<Id>();
      Set<String> setTerritoryCountry = new Set<String>();
      Map<Id, Contact> mapContact;

      for(Apttus_Proposal__Proposal__c proposal : listNewProposal) {
          if(proposal.Sold_To_Contact__c != null) {
              setContact.add(proposal.Sold_To_Contact__c);
          }
          //ESYS-12719
           setCheckSubmitForApprovalFlag(proposal);
      }

      System.debug('setContact: '+setContact);
      if(setContact.size() > 0){
        mapContact =  new map<ID, Contact>([Select id, MailingCountry, DSCORGPKG__DiscoverOrg_FullCountryName__c from Contact where id IN : setContact]);

        System.debug('mapContact: '+mapContact);
        if(mapContact.size() > 0){
          listTerritoryCountry = [Select name from Territory_Country__c where Global_Theater__c =: CPQ_Constants.RESTRICTED_COUNTRIES];

          for(Territory_Country__c terriroryCountry: listTerritoryCountry){
            setTerritoryCountry.add(terriroryCountry.name);
          }

          System.debug('listTerritoryCountry: '+listTerritoryCountry);
          System.debug('setTerritoryCountry: '+setTerritoryCountry);

          for(Apttus_Proposal__Proposal__c proposal : listNewProposal){
            Contact contact = mapContact.get(proposal.Sold_To_Contact__c);
            String contactCountry = contact.MailingCountry;
            System.debug('contactCountry: '+contactCountry);
            if(setTerritoryCountry != null && setTerritoryCountry.contains(contactCountry)){
                String label = Label.Quote_Create_Error1;
                String labelString = String.format(label, new String[]{contactCountry});
                proposal.addError(labelString);
            }
          }
        }
      }
    }


     //update create allowed ROE flag and display message
    public static void updateAllowedROEFlag(Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap){
      
      List<Territory_Country__c > listTerritoryCountry = new List<Territory_Country__c > ();
      Set<Id> setContact = new Set<Id>();
      Set<String> setTerritoryCountry = new Set<String>();
      Map<Id, Contact> mapContact;
      List<String> territoryCountry = new List<String>{CPQ_Constants.APAC,CPQ_Constants.LATAM, CPQ_Constants.MEXICO};

      for(Apttus_Proposal__Proposal__c proposal : newMap.values()) {

          if(((oldMap.get(proposal.Id)).Apttus_QPConfig__ConfigurationFinalizedDate__c == null
                && proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != null)
               || 
               (oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != null
                && oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c) ) {
                    
                        setContact.add(proposal.Sold_To_Contact__c);
                    
            }
      }

      try{

        if(setContact.size()>0)
             mapContact =  new map<ID, Contact>([Select id, MailingCountry, DSCORGPKG__DiscoverOrg_FullCountryName__c from Contact where id IN : setContact]);

        System.debug('mapContact: '+mapContact);
        if(mapContact!=null && mapContact.size() > 0){
          listTerritoryCountry = [Select name from Territory_Country__c where Global_Theater__c in :territoryCountry ];

          for(Territory_Country__c terriroryCountry: listTerritoryCountry){
            setTerritoryCountry.add(terriroryCountry.name);
          }

          for(Apttus_Proposal__Proposal__c proposal : newMap.values()){
            Contact contact = mapContact.get(proposal.Sold_To_Contact__c);
            String contactCountry = contact.MailingCountry;
            System.debug('contactCountry: '+contactCountry);
            if(setTerritoryCountry != null && setTerritoryCountry.contains(contactCountry)){
                proposal.CPQ_Allowed_ROE_Countries__c = true;
                //if(proposal.Total_Contract_Value_Non_Recurring__c + proposal.Total_Contract_Value_TCV_Recurring__c < 50000)
                //{
                //    String label = Label.Allowed_ROE_Countries_Error;
                //    proposal.addError(label);
                //}

            }
            else
                proposal.CPQ_Allowed_ROE_Countries__c = false;
          }
        }


      }

      catch(Exception ex){
                SystemMessage.log( 'CPQ_ProposalTriggerHelper method updateAllowedROEFlag failed', ex );
                System.debug('get message : '+ex.getMessage() + ' get line number ' + ex.getLineNumber());
            }

    }

    //Restrict user to update Quote for restricted countries, JIRA: #BC-805 - Added by Shikha Dave
    public static void restrictQuoteUpdateOnCountry(Map<Id,Apttus_Proposal__Proposal__c> mapOldProposal,Map<Id,Apttus_Proposal__Proposal__c> mapNewProposal){
      
      List<Territory_Country__c > listTerritoryCountry = new List<Territory_Country__c > ();
      Set<Id> setContact = new Set<Id>();
      Set<String> setTerritoryCountry = new Set<String>();
      Map<Id, Contact> mapContact;

      for(Apttus_Proposal__Proposal__c proposal : mapNewProposal.values()) {
          if((proposal.Sold_To_Contact__c != null)
             && (mapOldProposal.get(proposal.Id).Sold_To_Contact__c != proposal.Sold_To_Contact__c)) {
              setContact.add(proposal.Sold_To_Contact__c);
          }
      }

      //System.debug('setContact: '+setContact);
      if(setContact.size() > 0){
        mapContact =  new map<ID, Contact>([Select id, MailingCountry, DSCORGPKG__DiscoverOrg_FullCountryName__c from Contact where id IN : setContact]);

        //System.debug('mapContact: '+mapContact);
        if(mapContact.size() > 0){
          listTerritoryCountry = [Select name from Territory_Country__c where Global_Theater__c =: CPQ_Constants.RESTRICTED_COUNTRIES];

          for(Territory_Country__c terriroryCountry: listTerritoryCountry){
            setTerritoryCountry.add(terriroryCountry.name);
          }

          //System.debug('listTerritoryCountry: '+listTerritoryCountry);
          //System.debug('setTerritoryCountry: '+setTerritoryCountry);

          for(Apttus_Proposal__Proposal__c proposal : mapNewProposal.values()){
            if(mapContact.get(proposal.Sold_To_Contact__c)<>null && mapContact.get(proposal.Sold_To_Contact__c).MailingCountry <>null )
            {
                Contact contact = mapContact.get(proposal.Sold_To_Contact__c);
                String contactCountry = contact.MailingCountry;
                //System.debug('contactCountry: '+contactCountry);
                if(setTerritoryCountry != null && setTerritoryCountry.contains(contactCountry)){
                    String label = Label.Quote_Create_Error1;
                    String labelString = String.format(label, new String[]{contactCountry});
                    proposal.addError(labelString);
                }
            }
            
          }
        }
      }
    }

    //Restrict user to update Overage fields on Quote if Relay Partial is adeed, JIRA: #BC-1261 - Added by Shikha Dave
    public static void restrictOverageUpdate(Map<Id,Apttus_Proposal__Proposal__c> mapOldProposal,Map<Id,Apttus_Proposal__Proposal__c> mapNewProposal){

      Apttus_Proposal__Proposal__c mNew;
      Set<Id> setPropId = new Set<Id>();
      List<Apttus_Proposal__Proposal_Line_Item__c> listProposalLineItem = new List<Apttus_Proposal__Proposal_Line_Item__c> ();

      if(mapOldProposal.size() == mapNewProposal.size()) {
          for(Apttus_Proposal__Proposal__c mOld: mapOldProposal.values()){
              mNew=mapNewProposal.get(mOld.Id);

              if((mOld.Overage_Type__c != mNew.Overage_Type__c) || (mOld.Overage_Start_Date__c != mNew.Overage_Start_Date__c)
                || (mOld.Overage_End_Date__c != mNew.Overage_End_Date__c) || (mOld.Overage_Quantity__c != mNew.Overage_Quantity__c)){
                  setPropId.add(mNew.Id);
              }
              
          }
      }
      if(setPropId.size() > 0){
        listProposalLineItem = [select id, Apttus_Proposal__Proposal__c, Apttus_QPConfig__OptionId__r.Product_Group__c from Apttus_Proposal__Proposal_Line_Item__c where Apttus_QPConfig__OptionId__r.Product_Group__c includes (:CPQ_constants.EXCLUDED_FOR_OVERAGE_CASCADE) AND Apttus_Proposal__Proposal__c in :mapNewProposal.keyset() order by lastmodifieddate desc limit 1];
        System.debug('listProposalLineItem: '+listProposalLineItem);

        if(listProposalLineItem.size() > 0){
          for(Apttus_Proposal__Proposal__c proposal : mapNewProposal.values()){
              if(proposal.Id == listProposalLineItem.get(0).Apttus_Proposal__Proposal__c){
                proposal.addError(Label.Restrict_Overage_Update);
              }
          }
        }
      }
    }

    //Sync Line Item to Opportunity Line Item.- Added by Shikha Dave: JIRA BC-1038
    public static void syncLItoOpptyLIonPrimary(Map<Id,Apttus_Proposal__Proposal__c> mapOldProposal,Map<Id,Apttus_Proposal__Proposal__c> mapNewProposal)
    {
        //System.debug('in syncLItoOpptyLIonPrimary');
        try {
                Apttus_Proposal__Proposal__c mNew;
                Set<id> setNewPropId = New Set<id>();
                Map<ID, Apttus_Config2__ProductConfiguration__c> mapProdConfig = new map<ID, Apttus_Config2__ProductConfiguration__c>();

                if(mapOldProposal.size() == mapNewProposal.size())
                {
                  for(Apttus_Proposal__Proposal__c mOld: mapOldProposal.values()){
                      mNew=mapNewProposal.get(mOld.Id);
                      if(mNew.Apttus_Proposal__Primary__c == true && (mNew.Apttus_Proposal__Primary__c != mOld.Apttus_Proposal__Primary__c)) 
                      {
                          setNewPropId.add(mNew.Id);
                      }
                  }
                  mapProdConfig=new map<ID, Apttus_Config2__ProductConfiguration__c>([select Id, Apttus_QPConfig__Proposald__c, Apttus_Config2__Status__c from Apttus_Config2__ProductConfiguration__c where (Apttus_Config2__Status__c =:CPQ_Constants.FINALIZED OR Apttus_Config2__Status__c =:CPQ_Constants.SAVED) AND Apttus_QPConfig__Proposald__c IN: setNewPropId order by lastmodifieddate desc limit 1]);
              
                  if(!mapProdConfig.isEmpty()){
                      System.debug('**in Opp sync setProductConfigId--'+mapProdConfig.keySet());
                      CPQ_UtilityClass.syncLineItemtoOppotunityLI(mapProdConfig.keySet());
                  }
                }

        }
         catch(Exception ex){
                SystemMessage.log( 'CPQ_ProposalTriggerHelper method syncLItoOpptyLIonPrimary failed', ex );
                System.debug('get message : '+ex.getMessage() + ' get line number ' + ex.getLineNumber());
            }
        
    }
    
    //Added by Anay Bhande: JIRA BC-555 (Set Quote Owner)
    public static void setOwner(List <Apttus_Proposal__Proposal__c> newProposal, Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap){

        Set<Id> quoteOpportunities = new Set<ID>();
        Set<Id> validProposals = new Set<Id>();

        if(newProposal!=null)
        for(Apttus_Proposal__Proposal__c proposal : newProposal){
            if(String.isNotBlank(proposal.Apttus_Proposal__Opportunity__c) && (Trigger.isInsert||
              (proposal.Apttus_Proposal__Opportunity__c!=oldMap.get(proposal.Id).Apttus_Proposal__Opportunity__c))) {
                if(Trigger.isUpdate)
                validProposals.add(proposal.Id);
                quoteOpportunities.add(proposal.Apttus_Proposal__Opportunity__c);
            }
        }

        if(validProposals.size()>0)
        {
            System.debug('quoteOpportunities demo ' +  quoteOpportunities);
            Map<Id, Opportunity> mapOpptyIdToOpportunity = new Map<ID, Opportunity>(
                                                          [Select ID, Is_Channel__c, OwnerId, Owner.ProfileId, Sales_Rep_Channel_only__c, Sales_Rep_Channel_only__r.ProfileId 
                                                          From Opportunity Where ID in :quoteOpportunities]);

            //Checks if the new owner has read permission on Quote object
            System.debug('quoteOpportunities demo 2' +  mapOpptyIdToOpportunity);
            List<PermissionSet> lisPerm=[Select Id, ProfileId from PermissionSet Where 
                                        Id in (SELECT ParentId FROM ObjectPermissions WHERE SObjectType = :CPQ_Constants.QUOTE_API_NAME  AND PermissionsRead=true) 
                                        AND IsOwnedByProfile=true];

            Set<Id> ValidProfileIds=new Set<Id>();
            if(lisPerm!=null){
                for(PermissionSet perm:lisPerm){
                    ValidProfileIds.add(perm.ProfileId);
                }
            }
            //End of permission check        

            if(Trigger.isInsert){
                for(Apttus_Proposal__Proposal__c proposal : newProposal){
                   if(proposal.Apttus_Proposal__Opportunity__c <> null)
                   {
                      proposal.Is_Channel__c=mapOpptyIdToOpportunity.get(proposal.Apttus_Proposal__Opportunity__c).Is_Channel__c;
                      if(mapOpptyIdToOpportunity.get(proposal.Apttus_Proposal__Opportunity__c).Is_Channel__c){
                          if(ValidProfileIds.contains(mapOpptyIdToOpportunity.get(proposal.Apttus_Proposal__Opportunity__c).Sales_Rep_Channel_only__r.ProfileId)){
                              proposal.OwnerId=mapOpptyIdToOpportunity.get(proposal.Apttus_Proposal__Opportunity__c).Sales_Rep_Channel_only__c;
                          }
                      }
                      else{
                          if(ValidProfileIds.contains(mapOpptyIdToOpportunity.get(proposal.Apttus_Proposal__Opportunity__c).Owner.ProfileId)){
                              proposal.OwnerId=mapOpptyIdToOpportunity.get(proposal.Apttus_Proposal__Opportunity__c).Owner.Id;
                          }              
                      }
                      /* Uncomment if read permission check is not required
                      if(mapOpptyIdToOpportunity.get(proposal.Apttus_Proposal__Opportunity__c).Is_Channel__c){
                          proposal.OwnerId=mapOpptyIdToOpportunity.get(proposal.Apttus_Proposal__Opportunity__c).Sales_Rep_Channel_only__c;
                      }
                      else{
                          proposal.OwnerId=mapOpptyIdToOpportunity.get(proposal.Apttus_Proposal__Opportunity__c).Owner;
                      }
                      */
                  }    
                }
                            
            }
            else{
                for(Id pId:validProposals){
                  if(newMap.get(pId).Apttus_Proposal__Opportunity__c <> null)
                   {
                    system.debug('@@ test opp channel ' + mapOpptyIdToOpportunity.get(newMap.get(pId).Apttus_Proposal__Opportunity__c).Is_Channel__c);
                      //newMap.get(pId).Is_Channel__c=mapOpptyIdToOpportunity.get(newMap.get(pId).Apttus_Proposal__Opportunity__c).Is_Channel__c;
                    //Uncomment if Opportunity change should not affect Is Channel
                    if(oldMap.get(pId).Apttus_Proposal__Opportunity__c!=null){
                        newMap.get(pId).Is_Channel__c=mapOpptyIdToOpportunity.get(newMap.get(pId).Apttus_Proposal__Opportunity__c).Is_Channel__c;
                    }
                    
                    if(mapOpptyIdToOpportunity.get(newMap.get(pId).Apttus_Proposal__Opportunity__c).Is_Channel__c){
                        if(ValidProfileIds.contains(mapOpptyIdToOpportunity.get(newMap.get(pId).Apttus_Proposal__Opportunity__c).Sales_Rep_Channel_only__r.ProfileId)){
                            newMap.get(pId).OwnerId=mapOpptyIdToOpportunity.get(newMap.get(pId).Apttus_Proposal__Opportunity__c).Sales_Rep_Channel_only__c;
                        }
                    }
                    else{
                        if(ValidProfileIds.contains(mapOpptyIdToOpportunity.get(newMap.get(pId).Apttus_Proposal__Opportunity__c).Owner.ProfileId)){
                            newMap.get(pId).OwnerId=mapOpptyIdToOpportunity.get(newMap.get(pId).Apttus_Proposal__Opportunity__c).Owner.Id;
                        }              
                    }
                    /* Uncomment if read permission check is not required
                    if(mapOpptyIdToOpportunity.get(newMap.get(pId).Apttus_Proposal__Opportunity__c).Is_Channel__c){
                        newMap.get(pId).OwnerId=mapOpptyIdToOpportunity.get(newMap.get(pId).Apttus_Proposal__Opportunity__c).Sales_Rep_Channel_only__c;
                    }
                    else{
                        newMap.get(pId).OwnerId=mapOpptyIdToOpportunity.get(newMap.get(pId).Apttus_Proposal__Opportunity__c).Owner;
                    }
                    */
                   }
                    
                }          
            }          
        }
    }

    
    //Added by sunidhar to created Account location if it doen't exist or select the Id if already location is present
    public static void createOrAssignAccountLocation(list<Apttus_Proposal__Proposal__c> newProposal, map<id, Apttus_Proposal__Proposal__c> oldMapProposal) {
         system.Debug('## Rohit');
        set<string> eidIds = new set<string>();
        map<string,Apttus_Config2__AccountLocation__c> ac_map = new map<String,Apttus_Config2__AccountLocation__c>();
        map<string,Apttus_Config2__AccountLocation__c> ac_insert = new map<String,Apttus_Config2__AccountLocation__c>();
        list<Apttus_Proposal__Proposal__c> newapp = new list<Apttus_Proposal__Proposal__c>();
        map<Id,Id> quoteToLocation = new map<Id,Id>();
        list<Apttus_Config2__AccountLocation__c> ac_update = new list<Apttus_Config2__AccountLocation__c>();
        
        for(Apttus_Proposal__Proposal__c app : newProposal) {
            if(app.Box_Enterprise_ID__c <> null && app.Box_Enterprise_ID__c <> oldMapProposal.get(app.Id).Box_Enterprise_ID__c) {
                eidIds.add(app.Box_Enterprise_ID__c);
            }
        }
       
        if(eidIds.size()>0) {
            for(Apttus_Config2__AccountLocation__c ac : [SELECT id,BillTo_Contact__c,SoldTo_Contact__c,name,Past_Due_Balance__c,Apttus_Config2__AccountId__c,Is_Auto_renew_removed__c FROM Apttus_Config2__AccountLocation__c WHERE name IN : eidIds]) {
                ac_map.put(ac.name,ac);
            }
        }
        
        if(eidIds.size()>0) {
        
            for(Apttus_Proposal__Proposal__c app : newProposal) {
                if(ac_map.containsKey(app.Box_Enterprise_ID__c) && app.Apttus_Proposal__Account__c != ac_map.get(app.Box_Enterprise_ID__c).Apttus_Config2__AccountId__c) {
                    app.Box_Enterprise_ID__c.addError(System.Label.CPQ_EID_Error_Msg);
                    
                }
                else if(ac_map.containsKey(app.Box_Enterprise_ID__c)) {
               system.Debug('## Rohit'+ac_map.get(app.Box_Enterprise_ID__c));
                    app.Apttus_QPConfig__LocationId__c = ac_map.get(app.Box_Enterprise_ID__c).Id;
                    //JIRA #ESYS-12281 added field Is_Auto_renew_removed__c 
                  
                    app.Is_Auto_renew_removed__c = ac_map.get(app.Box_Enterprise_ID__c).Is_Auto_renew_removed__c;
                    if(app.Quote_Type__c == CPQ_constants.Cancellation && app.Quote_Type__c == CPQ_constants.NewVar)  //For new quotes and the cancellation Past_Due_Balance__c is not applicable
                    app.Bill_To_Account_Balance_Due__c = ac_map.get(app.Box_Enterprise_ID__c).Past_Due_Balance__c <> null?ac_map.get(app.Box_Enterprise_ID__c).Past_Due_Balance__c:null;    //Added By Sunidhar: JIRA 1269
                    quoteToLocation.put(app.Id,ac_map.get(app.Box_Enterprise_ID__c).Id);
                    if(ac_map.get(app.Box_Enterprise_ID__c).BillTo_Contact__c <> null && ac_map.get(app.Box_Enterprise_ID__c).BillTo_Contact__c <> app.Bill_To_Contact__c && ac_map.get(app.Box_Enterprise_ID__c).SoldTo_Contact__c <> null && ac_map.get(app.Box_Enterprise_ID__c).SoldTo_Contact__c <> app.Sold_To_Contact__c) {
                        Apttus_Config2__AccountLocation__c ac = new Apttus_Config2__AccountLocation__c();
                        ac.name = app.Box_Enterprise_ID__c;
                        ac.Id = ac_map.get(app.Box_Enterprise_ID__c).Id;
                        ac.BillTo_Contact__c = app.Bill_To_Contact__c;
                        ac.SoldTo_Contact__c = app.Sold_To_Contact__c;
                        ac_insert.put(ac.name,ac);
                    }
                }
                else {
                    Apttus_Config2__AccountLocation__c ac = new Apttus_Config2__AccountLocation__c();
                    ac.name = app.Box_Enterprise_ID__c;
                    ac.Apttus_Config2__AccountId__c = app.Apttus_Proposal__Account__c;
                    ac.BillTo_Contact__c = app.Bill_To_Contact__c;
                    ac.SoldTo_Contact__c = app.Sold_To_Contact__c;
                    //BC-2958 - Should use Box_Enterprise_ID__c from account location 
                    // ac.Enterprise_Id__c = app.Box_Enterprise_ID__c;
                    ac.Box_Enterprise_Id__c = app.Box_Enterprise_ID__c;
                    ac_insert.put(ac.name,ac);
                    newapp.add(app);
                }
            }
        }
        
        try {
            if(ac_insert.size()>0)
                upsert ac_insert.values();
        } catch(Exception ex){
            SystemMessage.log( 'CPQ_ProposalTriggerHelper method createOrAssignAccountLocation failed', ex );
            System.debug('get message : '+ex.getMessage() + ' get line number ' + ex.getLineNumber());
        }
        
        if(ac_insert.keySet().size()>0) {
            for(Apttus_Proposal__Proposal__c app : newapp) {
                if(ac_insert.containsKey(app.Box_Enterprise_ID__c)) {
                    app.Apttus_QPConfig__LocationId__c = ac_insert.get(app.Box_Enterprise_ID__c).Id;
                    quoteToLocation.put(app.Id,ac_insert.get(app.Box_Enterprise_ID__c).Id);
                    //Added By shiavni JIRA 1269
                   // if(ac_insert.get(app.Box_Enterprise_ID__c).Zuora_Billing_Account__r.Zuora__Balance__c<>null && ac_insert.get(app.Box_Enterprise_ID__c).Zuora_Billing_Account__r.Past_Due_Balance__c<Date.Today())
                           // app.Bill_To_Account_Balance_Due__c = true;
                    //END JIRA 1269
                }
            }
        }
        if(quoteToLocation.keySet().size()>0) {
      CPQ_ProposalTriggerHelper.setLocationForLiPli(quoteToLocation);
        }
    }
    
    public static void setLocationForLiPli(map<Id,id> quoteToLocation) {

        list<Apttus_Config2__LineItem__c> li_list = new list<Apttus_Config2__LineItem__c>();
        list<Apttus_Proposal__Proposal_Line_Item__c> pli_list = new list<Apttus_Proposal__Proposal_Line_Item__c>();
        list<Apttus_Config2__ProductConfiguration__c> pc_list = new list<Apttus_Config2__ProductConfiguration__c>();
        for(Apttus_Config2__LineItem__c li : [SELECT id,Apttus_Config2__LocationId__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c IN : quoteToLocation.keySet()]) {
            li.Apttus_Config2__LocationId__c = quoteToLocation.get(li.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c);
            li_list.add(li);
        }
        for(Apttus_Proposal__Proposal_Line_Item__c pli : [SELECT id,Apttus_QPConfig__LocationId__c,Apttus_Proposal__Proposal__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Apttus_Proposal__Proposal__c IN : quoteToLocation.keySet()]) {
            pli.Apttus_QPConfig__LocationId__c = quoteToLocation.get(pli.Apttus_Proposal__Proposal__c);
            pli_list.add(pli);
        }
        //START:JIRA: BC-1097 - Added by Shikha Dave
        for(Apttus_Config2__ProductConfiguration__c pc : [SELECT id,Apttus_Config2__LocationId__c,Apttus_QPConfig__Proposald__c FROM Apttus_Config2__ProductConfiguration__c WHERE Apttus_QPConfig__Proposald__c IN : quoteToLocation.keySet()]) {
            pc.Apttus_Config2__LocationId__c = quoteToLocation.get(pc.Apttus_QPConfig__Proposald__c);
            pc_list.add(pc);
        }

        try {
            if(pc_list.size()>0)
                update pc_list;
            //END:JIRA: BC-1097
            if(li_list.size()>0)
                update li_list;
            if(pli_list.size()>0)
                update pli_list;
        } catch(Exception ex){
            SystemMessage.log( 'CPQ_ProposalTriggerHelper method setLocationForLiPli failed', ex );
            System.debug('get message : '+ex.getMessage() + ' get line number ' + ex.getLineNumber());
        }
    }
    
    //Added by Anay Bhande: JIRA BC-556 (Checks if any approval related field is modified and sets approval required flag for it)
    public static void setApprovalFields(Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap){

        //BC-1335 (Change Record Types)

        Id LockedRecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Locked Proposal').getRecordTypeId(); 
        Id DirectExRecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Direct - Existing').getRecordTypeId(); 
        Id DirectNewRecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Direct - New').getRecordTypeId(); 
        Id ChannelExRecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Channel - Existing').getRecordTypeId(); 
        Id ChannelNewRecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Channel - New').getRecordTypeId(); 
        for(Id pId:newMap.keyset()){
            if(newMap.get(pId).Apttus_Proposal__Approval_Stage__c != oldMap.get(pId).Apttus_Proposal__Approval_Stage__c 
              && (newMap.get(pId).Apttus_Proposal__Approval_Stage__c==CPQ_Constants.APPROVED || 
                newMap.get(pId).Apttus_Proposal__Approval_Stage__c==CPQ_Constants.IN_REVIEW)){
                newMap.get(pId).RecordTypeId=LockedRecordTypeId;
            }
            else
            if(newMap.get(pId).Apttus_QPApprov__Approval_Status__c != oldMap.get(pId).Apttus_QPApprov__Approval_Status__c 
              && newMap.get(pId).Apttus_QPApprov__Approval_Status__c==CPQ_Constants.REJECTED){
                if(newMap.get(pId).Is_Channel__c && newMap.get(pId).Quote_Type__c==CPQ_Constants.NEWVAR){
                    newMap.get(pId).RecordTypeId=ChannelNewRecordTypeId;
                }
                if(newMap.get(pId).Is_Channel__c && newMap.get(pId).Quote_Type__c!=CPQ_Constants.NEWVAR){
                    newMap.get(pId).RecordTypeId=ChannelExRecordTypeId;
                }
                if(!newMap.get(pId).Is_Channel__c && newMap.get(pId).Quote_Type__c==CPQ_Constants.NEWVAR){
                    newMap.get(pId).RecordTypeId=DirectNewRecordTypeId;
                }
                if(!newMap.get(pId).Is_Channel__c && newMap.get(pId).Quote_Type__c!=CPQ_Constants.NEWVAR){
                    newMap.get(pId).RecordTypeId=DirectExRecordTypeId;
                }
            }            
        }

        // End of BC-1335 (Change Record Types)

        //BC-556, BC-3276

        Set<Id> ApprovedRejectedProposalSet=new Set<Id>();
        for(Id pId:newMap.keyset()){
            if(newMap.get(pId).Apttus_QPApprov__Approval_Status__c!= oldMap.get(pId).Apttus_QPApprov__Approval_Status__c &&
                (newMap.get(pId).Apttus_QPApprov__Approval_Status__c==CPQ_Constants.APPROVED || newMap.get(pId).Apttus_QPApprov__Approval_Status__c==CPQ_Constants.REJECTED)){
                ApprovedRejectedProposalSet.add(pId);
            }
        }
        List<Apttus_Approval__Approval_Request__c> listOfApprovalRequest=[Select Apttus_Approval__Step_Name__c, Apttus_Approval__Object_Id__c, Apttus_Approval__Approval_Status__c, Apttus_Approval__ChildObjectType__c
                                                                            from Apttus_Approval__Approval_Request__c where Apttus_Approval__Object_Id__c in :ApprovedRejectedProposalSet
                                                                            AND (Apttus_Approval__Assigned_To_Type__c = NULL OR Apttus_Approval__Assigned_To_Type__c = '')];

        if(listOfApprovalRequest!=NULL)
        for(Apttus_Approval__Approval_Request__c appr:listOfApprovalRequest){
            //System.debug(appr.Apttus_Approval__Object_Id__c+' '+appr.Apttus_Approval__Approval_Status__c);
            if(String.isNotBlank(appr.Apttus_Approval__Object_Id__c) && appr.Apttus_Approval__Approval_Status__c==CPQ_Constants.APPROVED 
                && String.isBlank(appr.Apttus_Approval__ChildObjectType__c) && newMap.get(appr.Apttus_Approval__Object_Id__c)!=NULL){
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.PAYMENT_FREQUENCY_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).Payment_Frequency_Approval_Required__c=false;
                }
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.AUTO_RENEW_REMOVAL_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).Auto_Renew_Removal_Approval_Required__c=false;
                }
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.PR_PROVISION_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).PR_Provision_Approval_Required__c=false;
                }
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.AFFILIATION_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).Affiliation_Approval_Required__c=false;
                }
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.DD_NEEDED_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).DD_Needed_Approval_Required__c=false;
                }
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.ORDER_VALUE_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).Order_Value_Approval_Required__c=false;
                }
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.TRUEUP_FREQUENCY_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).True_Up_Frequency_Approval_Required__c=false;
                }
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.ORDER_PRICE_CAP_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).Order_Price_Cap_Approval_Required__c=false;
                }
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.REMOVAL_OF_SERVICES_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).Removal_of_Services_Approval_Required__c=false;
                }
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.CUSTOM_TERMS_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).Custom_Terms_Approval_Required__c=false;
                }
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.BSA_PRICECAP_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).BSA_Price_Cap_Approval_Required__c=false;
                }
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.OVERAGE_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).Overage_Approval_Required__c=false;
                }
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.PAYMENT_TERM_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).Payment_Term_Approval_Required__c=false;
                }
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.ORDER_PAYMENT_TERM_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).Order_Payment_Term_Approval_Completed__c=false;
                }
                if(appr.Apttus_Approval__Step_Name__c.contains(CPQ_Constants.BSA_PAYMENT_TERM_APPROVAL)){
                    newMap.get(appr.Apttus_Approval__Object_Id__c).BSA_Payment_Term_Approval_Completed__c=false;
                }
            }
            if(String.isNotBlank(appr.Apttus_Approval__Object_Id__c) && appr.Apttus_Approval__Approval_Status__c==CPQ_Constants.REJECTED 
                && newMap.get(appr.Apttus_Approval__Object_Id__c)!=NULL && String.isNotBlank(appr.Apttus_Approval__ChildObjectType__c) 
                && appr.Apttus_Approval__ChildObjectType__c == CPQ_Constants.PROPOSAL_LINE_ITEM){
                newMap.get(appr.Apttus_Approval__Object_Id__c).Approval_Line_Level_Rejection__c =CPQ_Constants.APPROVAL_LINE_ERROR;
            }
        }

        //End of BC-556, BC-3276

        //Sets Additional Terms Present flag if Additional Terms is present
        for(Id pId:newMap.keyset()){
            if(String.isNotBlank(newMap.get(pId).Additional_Terms__c) && newMap.get(pId).Additional_Terms_Present__c!=true){
                  newMap.get(pId).Additional_Terms_Present__c=true;
            }
            else
            if(String.isBlank(newMap.get(pId).Additional_Terms__c) && newMap.get(pId).Additional_Terms_Present__c==true){
                  newMap.get(pId).Additional_Terms_Present__c=false;
            }
        } 
        //End of Additional Term Check
        
        for(Id pId:newMap.keyset()){
            if(newMap.get(pId).Seats_Sold__c!=oldMap.get(pId).Seats_Sold__c){
                newMap.get(pId).Payment_Frequency_Approval_Required__c=true;
                newMap.get(pId).Removal_of_BC_Cons_Approval_Required__c=true;
            }
            if(newMap.get(pId).Percent_Affiliate__c!=oldMap.get(pId).Percent_Affiliate__c){
                newMap.get(pId).Affiliation_Approval_Required__c=true;
            }
            if(newMap.get(pId).Payment_Frequency__c!=oldMap.get(pId).Payment_Frequency__c){
                newMap.get(pId).Payment_Frequency_Approval_Required__c=true;
            }
            if(newMap.get(pId).Is_Auto_renew_removed__c!=oldMap.get(pId).Is_Auto_renew_removed__c){
                newMap.get(pId).Auto_Renew_Removal_Approval_Required__c=true;
            }
            if((newMap.get(pId).Total_Contract_Value_Non_Recurring__c !=oldMap.get(pId).Total_Contract_Value_Non_Recurring__c )||
              (newMap.get(pId).Total_Contract_Value_TCV_Recurring__c !=oldMap.get(pId).Total_Contract_Value_TCV_Recurring__c )){
                newMap.get(pId).Auto_Renew_Removal_Approval_Required__c=true;
                newMap.get(pId).PR_Provision_Approval_Required__c=true;
                newMap.get(pId).Order_Value_Approval_Required__c=true;
                newMap.get(pId).Platinum_Services_Approval_Required__c=true;
                newMap.get(pId).Removal_of_Services_Approval_Required__c=true;
                newMap.get(pId).Premier_Services_Approval_Required__c=true;
                newMap.get(pId).Removal_of_BC_Cons_Approval_Required__c=true;
            }
            if(newMap.get(pId).PR_Provision_Modified__c!=oldMap.get(pId).PR_Provision_Modified__c){
                newMap.get(pId).PR_Provision_Approval_Required__c=true;
            }
            if(newMap.get(pId).Modified_by_Deal_Desk__c!=oldMap.get(pId).Modified_by_Deal_Desk__c){
                newMap.get(pId).DD_Needed_Approval_Required__c=true;
            }
            if(newMap.get(pId).True_Up_Frequency__c!=oldMap.get(pId).True_Up_Frequency__c){
                newMap.get(pId).True_Up_Frequency_Approval_Required__c=true;
            }
            if(newMap.get(pId).Count_of_Platinum_Services__c!=oldMap.get(pId).Count_of_Platinum_Services__c){
                newMap.get(pId).Platinum_Services_Approval_Required__c=true;
                newMap.get(pId).Removal_of_Services_Approval_Required__c=true;
            }
            if(newMap.get(pId).Order_Price_Cap__c!=oldMap.get(pId).Order_Price_Cap__c){
                newMap.get(pId).Order_Price_Cap_Approval_Required__c=true;
            }
            if(newMap.get(pId).Count_of_Premier_Services__c!=oldMap.get(pId).Count_of_Premier_Services__c){
                newMap.get(pId).Removal_of_Services_Approval_Required__c=true;
                newMap.get(pId).Premier_Services_Approval_Required__c=true;
            }
            if(newMap.get(pId).Additional_Terms_Present__c!=oldMap.get(pId).Additional_Terms_Present__c){
                newMap.get(pId).Custom_Terms_Approval_Required__c=true;
            }
            if(newMap.get(pId).BSA_Price_Cap__c!=oldMap.get(pId).BSA_Price_Cap__c){
                newMap.get(pId).BSA_Price_Cap_Approval_Required__c=true;
            }
            if((newMap.get(pId).Overage_Quantity__c !=oldMap.get(pId).Overage_Quantity__c) || (newMap.get(pId).Seats_Sold__c !=oldMap.get(pId).Seats_Sold__c)  || (newMap.get(pId).Platform_Seats__c !=oldMap.get(pId).Platform_Seats__c) ){
                newMap.get(pId).Overage_Approval_Required__c=true;
            }
            if(newMap.get(pId).Apttus_Proposal__Payment_Term__c!=oldMap.get(pId).Apttus_Proposal__Payment_Term__c){
                newMap.get(pId).Payment_Term_Approval_Required__c=true;
                newMap.get(pId).BSA_Payment_Term_Approval_Completed__c=true;
                newMap.get(pId).Order_Payment_Term_Approval_Completed__c=true;
            }
            if(newMap.get(pId).Order_Payment_Term__c!=oldMap.get(pId).Order_Payment_Term__c){
                newMap.get(pId).Order_Payment_Term_Approval_Completed__c=true;
            }
            if(newMap.get(pId).Count_of_BC_Consulting__c!=oldMap.get(pId).Count_of_BC_Consulting__c){
                newMap.get(pId).Removal_of_BC_Cons_Approval_Required__c=true;
            }
            if(newMap.get(pId).BSA_Payment_Term__c!=oldMap.get(pId).BSA_Payment_Term__c){
                newMap.get(pId).BSA_Payment_Term_Approval_Completed__c=true;
            }
        }
    }
   
    /*
    @Author : Shivani Rathod
    @JIRA : BC-4375
    @purpose :  Used to populate filed Display_CustomSkills_Clause_Template__c on service order document info (child object of proposal) , that is used in templates to display clause of custom skills if this is true.
    */
    public static boolean isSkillsOnly(String Recurring_Product_Name_Amended){


                   if(Recurring_Product_Name_Amended != null 
                    && Recurring_Product_Name_Amended.contains(CPQ_Constants.BOX_CUSTOM_SKILLS) 
                    && !Recurring_Product_Name_Amended.contains(CPQ_Constants.platformEnterprise) 
                    && !Recurring_Product_Name_Amended.contains(CPQ_Constants.platformView)
                    && !Recurring_Product_Name_Amended.contains(CPQ_Constants.enterpriseAccountLicenses) 
                    && !Recurring_Product_Name_Amended.contains(CPQ_Constants.BUSINESS_ACCOUNT_LICENSES) 
                    && !Recurring_Product_Name_Amended.contains(CPQ_Constants.businessPlusAccountLicenses)
                    && !Recurring_Product_Name_Amended.contains(CPQ_Constants.monthlyActiveUsers) 
                    && !Recurring_Product_Name_Amended.contains(CPQ_Constants.platformStorage) 
                    && !Recurring_Product_Name_Amended.contains(CPQ_Constants.platformBandwidth)
                    && !Recurring_Product_Name_Amended.contains(CPQ_Constants.monthlyPlatformAPI))
                        return true;
                    else
                        return false;

    }

    /*
    @Author : Shivani Rathod
    @JIRA : BC-4375
    @purpose :  Used to populate filed on service order document info (child object of proposal) , that is used in templates to display those fields. 
    */
    public static void setCustomSkillsFields(Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap){

        system.debug('invoke setCustomSkillsFields');
        set<Id> setFinalizedProposalIds = new set<Id>();
        for(Apttus_Proposal__Proposal__c proposal : newMap.values()) {
            if(((oldMap.get(proposal.Id)).Apttus_QPConfig__ConfigurationFinalizedDate__c == null
                && proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != null)
               || 
               (oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != null
                && oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c) ) {
                    
                        setFinalizedProposalIds.add(proposal.Id);
                    
            }
        }   

        CPQ_Service_Order_Helper.setCustomSkillsFields(setFinalizedProposalIds);
           

    }

    //Added by Abhishek Awasthi: JIRA BC-491  (recurring products should be copied to quote for Finalized Proposals)
    public static void setRecurringProductsOnFinalization(Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap){
         system.debug('setRecurringProductsOnFinalization');
        set<Id> setFinalizedProposalIds = new set<Id>();
        for(Apttus_Proposal__Proposal__c proposal : newMap.values()) {
            if(((oldMap.get(proposal.Id)).Apttus_QPConfig__ConfigurationFinalizedDate__c == null
                && proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != null)
               || 
               (oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != null
                && oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c) ) {
                    
                        setFinalizedProposalIds.add(proposal.Id);
                    
            }
        }            
        if(setFinalizedProposalIds.size() > 0) {

            try {
                    
                  // 27/04/2018 - Modified query to get bundles in the list BC-837 - Yash
                  List<Apttus_Proposal__Proposal_Line_Item__c> ProposalLineItemList = [Select  Product_Option_Name__c, Apttus_Proposal__Proposal__c, 
                                                          Apttus_QPConfig__LineType__c, Monthly_Active_Users__c, Monthly_Platform_API_Calls__c,
                                                          Monthly_Platform_Bandwidth_GB__c, Platform_Storage_GB__c, Product_Sub_Family__c, 
                                                          Apttus_QPConfig__AttributeValueId__r.Delta_Monthly_Active_Users__c,
                                                          Apttus_QPConfig__AttributeValueId__r.Delta_Monthly_Platform_API_Calls__c,
                                                          Apttus_QPConfig__AttributeValueId__r.Monthly_Platform_API_Calls__c,
                                                          Apttus_QPConfig__AttributeValueId__r.Delta_Monthly_Platform_Bandwidth_GB__c,
                                                          Apttus_QPConfig__AttributeValueId__r.Monthly_Platform_Bandwidth_GB__c,
                                                          Apttus_QPConfig__AttributeValueId__r.Delta_Platform_Storage_GB__c,
                                                          Incremental_Quantity__c, Apttus_QPConfig__Quantity2__c, Net_Price__c,
                                                          Apttus_QPConfig__AttributeValueId__r.Primary_Zone__c, Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c,
                                                          Apttus_QPConfig__AttributeValueId__r.Secondary_Zone__c, Apttus_QPConfig__LineStatus__c,
                                                          Apttus_QPConfig__AttributeValueId__r.Monthly_Active_Users_Total__c,Product_Option_Code__c,
                                                          Apttus_QPConfig__AttributeValueId__r.Monthly_Platform_API_Calls_Total__c,
                                                          Apttus_QPConfig__AttributeValueId__r.Monthly_Platform_Bandwidth_GB_Total__c,
                                                          Apttus_QPConfig__AttributeValueId__r.Platform_Storage_GB_Total__c
                                                          from Apttus_Proposal__Proposal_Line_Item__c
                                                          where Apttus_Proposal__Proposal__c in :setFinalizedProposalIds and Apttus_QPConfig__PriceType__c = : CPQ_Constants.RECURRING]; 
                  
                  Map<Id, String> ProposaltoNameMap=new Map<Id,String>();
                  Map<Id, String> ProposaltoBundleMap=new Map<Id,String>();
                  Map<Id, String> ProposaltoAddOneMap=new Map<Id,String>();
                  Map<Id, String> ProposaltoAmendedMap=new Map<Id,String>();
                  Map<Id, String> ProposaltoAllRecurringMap=new Map<Id,String>();
                  set<string> PLATFORM_ADDITIONAL_OPTIONS = CPQ_UtilityClass.getPlatformAdditionalOptions();
                  // 27/04/2018 - Modified loops to build bundles Map in the list BC-837 - Yash 
                  for(Id propId: setFinalizedProposalIds){
                      ProposaltoNameMap.put(propId, '');
                      ProposaltoBundleMap.put(propId, '');
                      ProposaltoAddOneMap.put(propId, '');
                      ProposaltoAmendedMap.put(propId, '');
                      ProposaltoAllRecurringMap.put(propId, '');
                  }
                  system.debug('checking1'+ProposalLineItemList.size());
                  for (Apttus_Proposal__Proposal_Line_Item__c PLI : ProposalLineItemList)  {
                    if (PLI.Apttus_QPConfig__AttributeValueId__r.Primary_Zone__c != '' && PLI.Apttus_QPConfig__AttributeValueId__r.Secondary_Zone__c != '') {
                      newMap.get(PLI.Apttus_Proposal__Proposal__c).Location_1__c = PLI.Apttus_QPConfig__AttributeValueId__r.Primary_Zone__c;
                      newMap.get(PLI.Apttus_Proposal__Proposal__c).Location_2__c = PLI.Apttus_QPConfig__AttributeValueId__r.Secondary_Zone__c;
                    }
                    if (PLI.Apttus_QPConfig__LineStatus__c==CPQ_Constants.AMENDED)
                      ProposaltoAmendedMap.put(PLI.Apttus_Proposal__Proposal__c,ProposaltoAmendedMap.get(PLI.Apttus_Proposal__Proposal__c) + ', ' + PLI.Product_Option_Name__c);
                    if (PLI.Apttus_QPConfig__LineType__c == CPQ_constants.OPTION || PLI.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c==CPQ_Constants.STANDALONE) {
                      String name=ProposaltoNameMap.get(PLI.Apttus_Proposal__Proposal__c);
                      if(String.isNotBlank(name)){
                          name+=', ';
                      }
                      name+=PLI.Product_Option_Name__c;
                      if (PLI.Apttus_QPConfig__LineStatus__c != CPQ_Constants.CANCELLED) {
                          ProposaltoAllRecurringMap.put(PLI.Apttus_Proposal__Proposal__c,name);
                      }
                      if ((PLI.Apttus_QPConfig__LineStatus__c==CPQ_Constants.NEWVAR) || (PLI.Apttus_QPConfig__LineStatus__c==CPQ_Constants.RENEWED))
                          ProposaltoNameMap.put(PLI.Apttus_Proposal__Proposal__c,name);
                      if (PLATFORM_ADDITIONAL_OPTIONS.contains(PLI.Product_Option_Code__c) && PLI.Product_Sub_Family__c == CPQ_constants.ADDITIONAL_RESOURCES_SUB_FAMILY && PLI.Apttus_QPConfig__LineStatus__c != CPQ_Constants.CANCELLED){
                        system.debug('checking1');
                        if (PLI.Product_Option_Code__c == CPQ_ProductConstants.PROD_CODE_PLATFORM_MAU) {
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Monthly_Active_Users_Additional__c = PLI.Monthly_Active_Users__c;
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Delta_Monthly_Active_Users_Additional__c = PLI.Apttus_QPConfig__AttributeValueId__r.Monthly_Active_Users_Total__c;
                        } else if (PLI.Product_Option_Code__c == CPQ_ProductConstants.PROD_CODE_PLATFORM_API) {
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Monthly_Platform_API_Calls_Additional__c = PLI.Monthly_Platform_API_Calls__c * 1000;
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Delta_Monthly_Platform_API_Calls_Addnl__c = PLI.Apttus_QPConfig__AttributeValueId__r.Monthly_Platform_API_Calls_Total__c* 1000;
                        } else if (PLI.Product_Option_Code__c == CPQ_ProductConstants.PROD_CODE_PLATFORM_BANDWIDTH) {
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Monthly_Platform_Bandwidth_Additional__c = PLI.Monthly_Platform_Bandwidth_GB__c;
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Delta_Monthly_Platform_Bandwidth_Addnl__c = PLI.Apttus_QPConfig__AttributeValueId__r.Monthly_Platform_Bandwidth_GB_Total__c;
                        } else if (PLI.Product_Option_Code__c == CPQ_ProductConstants.PROD_CODE_PLATFORM_STORAGE) {
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Platform_Storage_GB_Additional__c = PLI.Platform_Storage_GB__c;
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Delta_Platform_Storage_GB_Additional__c = PLI.Apttus_QPConfig__AttributeValueId__r.Platform_Storage_GB_Total__c;
                        }
                        //newMap.get(PLI.Apttus_Proposal__Proposal__c).Additional_Incremental_Qty__c = PLI.Incremental_Quantity__c;
                        //newMap.get(PLI.Apttus_Proposal__Proposal__c).Additional_Qty__c = PLI.Apttus_QPConfig__Quantity2__c;
                        if (PLI.Product_Option_Name__c != null){
                          String addOns=ProposaltoAddOneMap.get(PLI.Apttus_Proposal__Proposal__c);
                          if(String.isNotBlank(addOns)){
                              addOns+=', ';
                          }
                          addOns+=PLI.Product_Option_Name__c;
                          ProposaltoAddOneMap.put(PLI.Apttus_Proposal__Proposal__c,addOns);
                        }
                      } else if (PLI.Product_Option_Code__c == CPQ_ProductConstants.PROD_CODE_PLATFORM_ENTERPRISE && PLI.Apttus_QPConfig__LineStatus__c != CPQ_Constants.CANCELLED) {
                        newMap.get(PLI.Apttus_Proposal__Proposal__c).Platform_Enterprise_Incremental_Qty__c = PLI.Incremental_Quantity__c;
                        newMap.get(PLI.Apttus_Proposal__Proposal__c).Platform_Enterprise_Qty__c = PLI.Apttus_QPConfig__Quantity2__c;
                        newMap.get(PLI.Apttus_Proposal__Proposal__c).Blended_Net_Price_Platform__c = PLI.Net_Price__c;
                      } else if (PLI.Product_Option_Code__c == CPQ_ProductConstants.PROD_CODE_PLATFORM_VIEW_BNDL && PLI.Apttus_QPConfig__LineStatus__c != CPQ_Constants.CANCELLED) {
                         system.debug('@@ PLI.Incremental_Quantity__c ' + PLI.Incremental_Quantity__c);
                         newMap.get(PLI.Apttus_Proposal__Proposal__c).View_Incremental_Qty__c = PLI.Incremental_Quantity__c;
                         newMap.get(PLI.Apttus_Proposal__Proposal__c).View_Qty__c = PLI.Apttus_QPConfig__Quantity2__c;
                      } else if (PLI.Product_Sub_Family__c == CPQ_constants.PLATFORM_SUB_FAMILY && PLI.Product_Option_Name__c != null) {
                        String addOns=ProposaltoAddOneMap.get(PLI.Apttus_Proposal__Proposal__c);
                        if(String.isNotBlank(addOns)){
                            addOns+=', ';
                        }
                        addOns+=PLI.Product_Option_Name__c;
                        ProposaltoAddOneMap.put(PLI.Apttus_Proposal__Proposal__c,addOns);
                      }
                    } else if (PLI.Apttus_QPConfig__LineType__c == CPQ_constants.LINE_TYPE_PRODUCT_SERVICE) {
                      String name=ProposaltoBundleMap.get(PLI.Apttus_Proposal__Proposal__c);
                      if(String.isNotBlank(name)){
                          name+=', ';
                      }
                      name+=PLI.Product_Option_Name__c;
                      if ((PLI.Apttus_QPConfig__LineStatus__c==CPQ_Constants.NEWVAR) || (PLI.Apttus_QPConfig__LineStatus__c==CPQ_Constants.RENEWED))
                          ProposaltoBundleMap.put(PLI.Apttus_Proposal__Proposal__c,name);
                    }
                    if (PLI.Product_Option_Code__c == CPQ_ProductConstants.PROD_CODE_PLATFORM_BNDL && PLI.Apttus_QPConfig__LineStatus__c != CPQ_Constants.CANCELLED) {
                      newMap.get(PLI.Apttus_Proposal__Proposal__c).Monthly_Active_Users__c = PLI.Monthly_Active_Users__c;
                      newMap.get(PLI.Apttus_Proposal__Proposal__c).Monthly_Platform_API_Calls_Platform__c = PLI.Monthly_Platform_API_Calls__c * 1000;
                      newMap.get(PLI.Apttus_Proposal__Proposal__c).Monthly_Platform_Bandwidth_Platform__c = PLI.Monthly_Platform_Bandwidth_GB__c;
                      newMap.get(PLI.Apttus_Proposal__Proposal__c).Platform_Storage_GB_Platform__c = PLI.Platform_Storage_GB__c;
                      newMap.get(PLI.Apttus_Proposal__Proposal__c).Delta_Monthly_Active_Users_Platform__c = PLI.Apttus_QPConfig__AttributeValueId__r.Delta_Monthly_Active_Users__c;
                      newMap.get(PLI.Apttus_Proposal__Proposal__c).Delta_MonthlyPlatform_API_Calls_Platform__c = PLI.Apttus_QPConfig__AttributeValueId__r.Delta_Monthly_Platform_API_Calls__c * 1000;
                      newMap.get(PLI.Apttus_Proposal__Proposal__c).Delta_MonthlyPlatform_Bandwidth_Platform__c = PLI.Apttus_QPConfig__AttributeValueId__r.Delta_Monthly_Platform_Bandwidth_GB__c;
                      newMap.get(PLI.Apttus_Proposal__Proposal__c).Delta_Platform_Storage_GB_Platform__c = PLI.Apttus_QPConfig__AttributeValueId__r.Delta_Platform_Storage_GB__c;
                    } else if (PLI.Product_Option_Code__c == CPQ_ProductConstants.PROD_CODE_PLATFORM_VIEW_BNDL && PLI.Apttus_QPConfig__LineStatus__c != CPQ_Constants.CANCELLED) {
                       newMap.get(PLI.Apttus_Proposal__Proposal__c).Monthly_Platform_API_Calls_View__c = PLI.Monthly_Platform_API_Calls__c * 1000;
                       newMap.get(PLI.Apttus_Proposal__Proposal__c).Monthly_Platform_Bandwidth_View__c = PLI.Monthly_Platform_Bandwidth_GB__c;
                       newMap.get(PLI.Apttus_Proposal__Proposal__c).Platform_Storage_GB__c = PLI.Platform_Storage_GB__c;
                       newMap.get(PLI.Apttus_Proposal__Proposal__c).Delta_Monthly_Platform_API_Calls_View__c = PLI.Apttus_QPConfig__AttributeValueId__r.Delta_Monthly_Platform_API_Calls__c * 1000;
                       newMap.get(PLI.Apttus_Proposal__Proposal__c).Delta_Monthly_Platform_Bandwidth_View__c = PLI.Apttus_QPConfig__AttributeValueId__r.Delta_Monthly_Platform_Bandwidth_GB__c;
                       newMap.get(PLI.Apttus_Proposal__Proposal__c).Delta_Platform_Storage_GB_View__c = PLI.Apttus_QPConfig__AttributeValueId__r.Delta_Platform_Storage_GB__c;
                    }
                    System.debug('ProposaltoAmendedMap.get(PLI.Apttus_Proposal__Proposal__c) ' + ProposaltoAmendedMap.get(PLI.Apttus_Proposal__Proposal__c));
                  }
                  for(Id propId: setFinalizedProposalIds){
                      newMap.get(propId).Recurring_Product_Name__c=ProposaltoNameMap.get(propId);
                      newMap.get(propId).Recurring_Bundle_Names__c=ProposaltoBundleMap.get(propId);
                      newMap.get(propId).Platform_and_Additional_Add_Ons__c=ProposaltoAddOneMap.get(propId);
                      newMap.get(propId).Recurring_Product_Name_Amended__c=ProposaltoAmendedMap.get(propId);
                      newMap.get(propId).Recurring_Products_Name_All__c = ProposaltoAllRecurringMap.get(propId);

                      // BC-4375 - Set Display_CustomSkills_Clause_Template__c to display custom skills clause in document if it is true.
                      String Recurring_Product_Name_Amended = ProposaltoAmendedMap.get(propId);
                      String Recurring_Product_Name = ProposaltoNameMap.get(propId);
                      if(Recurring_Product_Name_Amended.contains(CPQ_Constants.BOX_CUSTOM_SKILLS))
                      newMap.get(propId).Display_CustomSkills_Clause_Template__c = isSkillsOnly(Recurring_Product_Name_Amended);
                      else if(Recurring_Product_Name.contains(CPQ_Constants.BOX_CUSTOM_SKILLS))
                      newMap.get(propId).Display_CustomSkills_Clause_Template__c = isSkillsOnly(Recurring_Product_Name);
                    }
                    
              }
              catch(Exception ex)  {
                    SystemMessage.log( 'CPQ_ProposalTriggerHelper method setRecurringProductsOnFinalization failed', ex );                
                    System.debug(ex.getMessage());
              }    
        }
    } 

    /**
     * @description: Added by Shivani Rathod: JIRA BC- 3564 show approvals button
     *
     * @param: { Map<Id,Apttus_Proposal__Proposal__c> } newMap - new proposal version with id as key
     * @param: { Map<Id,Apttus_Proposal__Proposal__c> } oldMap - old proposal version with id as key
     * @return: none
     */
    public static void setCheckSubmitForApproval( Map<Id,Apttus_Proposal__Proposal__c> newMap, Map<Id,Apttus_Proposal__Proposal__c> oldMap ) {

        try {
            System.Debug('####setCheckSubmitForApproval');
            for( Apttus_Proposal__Proposal__c proposal : newMap.values() ) {

                Apttus_Proposal__Proposal__c oldProposal = oldMap.get(proposal.Id);

                // if a new cart is finalized && TCV Recurring + TCV Non-recurring > 0
                //ESYS-12719
                //if( oldProposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c ){
                  if( oldProposal.Payment_Method__c != proposal.Payment_Method__c){
                       //ESYS-12719
                     setCheckSubmitForApprovalFlag(proposal);
                }
            }
        }
        catch( Exception ex ) {

            SystemMessage.log( 'CPQ_ProposalTriggerHelper method setCheckSubmitForApproval failed', ex );
            System.debug(' message' + ex.getMessage() + ' line number ' + ex.getLineNumber());
        }   
    }

    /**
     * @description: determines if a default payment method should be set and sets the Payment_Method__c field
     *
     * @param: { Map<Id,Apttus_Proposal__Proposal__c> } newMap - new proposal version with id as key
     * @param: { Map<Id,Apttus_Proposal__Proposal__c> } oldMap - old proposal version with id as key
     * @return: none
     */
    public static void setDefaultPaymentMethod( Map<Id,Apttus_Proposal__Proposal__c> newMap, Map<Id,Apttus_Proposal__Proposal__c> oldMap ) {

        for( Apttus_Proposal__Proposal__c proposal : newMap.values() ) {

            Apttus_Proposal__Proposal__c oldProposal = oldMap.get(proposal.Id);

            Double totalArrUSD = CPQ_ProposalUtility.getTotalArrUSD( proposal );

            if( oldProposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c
                && proposal.Quote_Type__c == CPQ_constants.NEWVAR 
                && totalArrUSD > 0 ){

                if( totalArrUSD > 20000 )
                    proposal.Payment_Method__c = CPQ_Constants.PAYMENT_METHOD_CHECK;
            }
        }
    }

    //Added by Shivani Rathod: JIRA BC- 991 /992  (Custom BSA link should be copied from the account to quote for Finalized Proposals)
    public static void setCustomBSALinkOnFinalization(Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap) {

         set<Id> setFinalizedProposalIds = new set<Id>();
         Map<Id,String> ProposalToBSALink = new Map<Id,String>();
         Map<Id,Standard_BSA_Link__c> countryToLink = new Map<Id,Standard_BSA_Link__c>();
         Set<Id> setAccountsOfFinalizedProposals = new Set<Id> ();
         for(Apttus_Proposal__Proposal__c proposal : newMap.values()) {
           if(((oldMap.get(proposal.Id)).Apttus_QPConfig__ConfigurationFinalizedDate__c == null
                && proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != null)
               || 
               (oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != null
                && oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c) ) {
                   
                        setFinalizedProposalIds.add(proposal.Id);    
            }
          }
          System.debug('partnerProgramList Size:' + setFinalizedProposalIds);
            if(setFinalizedProposalIds.size() > 0) {

              try {
                     List<Apttus_Proposal__Proposal__c> setFinalizedProposals = [select id,Sold_To_Account__r.Custom_BSA_Link__c,Sold_To_Account__c,Apttus_Proposal__Opportunity__r.Box_Partner_Account__c,Apttus_Proposal__Opportunity__r.Box_Partner_Account__r.Custom_BSA_Link__c,
                                                                                      Apttus_Proposal__Account__r.Custom_Addendum_Link__c,Is_Channel__c from Apttus_Proposal__Proposal__c where Id in :setFinalizedProposalIds];
                           for(Apttus_Proposal__Proposal__c oProposal : setFinalizedProposals)
                           {
                           // Yash - BC-1258
                           if(oProposal.Sold_To_Account__c <> null && oProposal.Sold_To_Account__r.Custom_BSA_Link__c <> null) 
                                      ProposalToBSALink.put(oProposal.Id,oProposal.Sold_To_Account__r.Custom_BSA_Link__c);
                           setAccountsOfFinalizedProposals.add (oProposal.Apttus_Proposal__Opportunity__r.Box_Partner_Account__c);
                           }
                           System.debug('ProposalToBSALink.get(proposal.Id) demo ' + ProposalToBSALink);
                           List<Standard_BSA_Link__c> standardBSALinks = [select Id,Standard_Japan_BSA_Link__c,Standard_ROW_BSA_Link__c,Standard_US_BSA_Link__c,Name from Standard_BSA_Link__c];
                           for(Standard_BSA_Link__c StandardBSALink : standardBSALinks)
                           {
                             if(StandardBSALink.Name =='System Properties')
                             {
                                countryToLink.put(StandardBSALink.Id,StandardBSALink);
                             }
                           }
                          for( Apttus_Proposal__Proposal__c proposal : newMap.values()) {
                              if(!ProposalToBSALink.containsKey(proposal.Id) && countryToLink<>null){
                                 for(Standard_BSA_Link__c StandardLink : countryToLink.values()) {
                                          proposal.Custom_BSA_Link__c = StandardLink.Standard_US_BSA_Link__c;
                                    if((proposal.Billing_Country__c <> null && proposal.Billing_Country__c.equalsIgnoreCase(CPQ_constants.countryUS) || proposal.Billing_Country__c.equalsIgnoreCase(CPQ_constants.countryUSFull)) && StandardLink.Standard_US_BSA_Link__c != null )
                                          proposal.Custom_BSA_Link__c = StandardLink.Standard_US_BSA_Link__c;
                                    else if(proposal.Billing_Country__c<>null && proposal.Billing_Country__c.equalsIgnoreCase(CPQ_constants.countryJapan) && StandardLink.Standard_Japan_BSA_Link__c != null) 
                                          proposal.Custom_BSA_Link__c = StandardLink.Standard_Japan_BSA_Link__c;
                                    else if(StandardLink.Standard_ROW_BSA_Link__c != null && proposal.Billing_Country__c <> null &&  !proposal.Billing_Country__c.equalsIgnoreCase(CPQ_constants.countryUS) && !proposal.Billing_Country__c.equalsIgnoreCase(CPQ_constants.countryJapan) 
                                                                                          && !proposal.Billing_Country__c.equalsIgnoreCase(CPQ_constants.countryUSFull))
                                          proposal.Custom_BSA_Link__c = StandardLink.Standard_ROW_BSA_Link__c;
                                 }
                                    
                              }
                              else
                              {
                                System.debug('ProposalToBSALink.get(proposal.Id) ' + ProposalToBSALink.get(proposal.Id));
                                proposal.Custom_BSA_Link__c = ProposalToBSALink.get(proposal.Id);
                              }
                          }
                          
                     // Yash - BC-1258
                     List<Partner_Program__c> partnerProgramList = [SELECT id, Account__c, Link_to_Partner_Agreement__c, Partner_Program__c FROM Partner_Program__c WHERE Account__c IN :setAccountsOfFinalizedProposals 
                                                                        AND Partner_Program__c = :CPQ_Constants.PARTNER_PROGRAM_RESELLER AND Link_to_Partner_Agreement__c <> ''];
                     Map<Id, String> mapAccountToPartnerProgram = new Map<Id, String> ();
                     System.debug('partnerProgramList Size:' + partnerProgramList);
                     for (Partner_Program__c program : partnerProgramList) {
                       if (!mapAccountToPartnerProgram.containsKey(program.Account__c)){
                         mapAccountToPartnerProgram.put (program.Account__c, program.Link_to_Partner_Agreement__c);
                       }
                     }
                     for(Apttus_Proposal__Proposal__c proposal : setFinalizedProposals) {
                       System.debug('partnerProgramList Size:' + proposal.Apttus_Proposal__Opportunity__r.Box_Partner_Account__c);
                       if (mapAccountToPartnerProgram.containsKey(proposal.Apttus_Proposal__Opportunity__r.Box_Partner_Account__c)) {
                         newMap.get(proposal.id).Reseller_BSA_Link__c = mapAccountToPartnerProgram.get(proposal.Apttus_Proposal__Opportunity__r.Box_Partner_Account__c);
                       }
                     }

              }

              catch(Exception ex)  {
                    SystemMessage.log( 'CPQ_ProposalTriggerHelper method setCustomBSALinkOnFinalization failed', ex );
                    System.debug(ex.getMessage() + ' get line number ' + ex.getLineNumber());
              }   
           } 
    }
    
      //Added by Shivani Rathod: JIRA BC-535 / 536  (Custom BSA link/ custom Addendum Link should be copied from the account to quote for Finalized Proposals)
    public static void setCustomAddendumLinkOnFinalization(Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap){
        set<Id> setFinalizedProposalIds = new set<Id>();
        set<String> AccountIds = new set<String>();
        Map<String,List<Custom_Link_and_Addendum__c>> CustomLinks = new Map<String,List<Custom_Link_and_Addendum__c>>();
        //Set<Id> Set_opportunity_ID = new  Set<Id>();
        Map<Id,boolean> Is_Box_keysafe_and_premier_services = new Map<Id,boolean>(); // added by shivani for JIRA 887
        Map<Id,List<String>> proposalToProductCode = new Map<Id,List<String>>();

        // get default values for custom skills from custom settings
        CPQ_Custom_Addendum_Link__c customSkills = CPQ_Custom_Addendum_Link__c.getValues(CPQ_constants.SYSTEM_PROPERTIES);
        
        //System.debug(' Values ' + newMap.values());
        for(Apttus_Proposal__Proposal__c proposal : newMap.values()) {
           if(((oldMap.get(proposal.Id)).Apttus_QPConfig__ConfigurationFinalizedDate__c == null
                && proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != null)
               || 
               (oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != null
                && oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c) ) {
                   
                        setFinalizedProposalIds.add(proposal.Id);
                        //Set_opportunity_ID.add(proposal.Apttus_Proposal__Opportunity__c);            
                      }
        }            
        
        if(setFinalizedProposalIds.size() > 0) {

            try {
                    
                  List<Apttus_Proposal__Proposal_Line_Item__c> ProposalList = [Select id,Apttus_QPConfig__OptionId__r.Name ,Product_Option_Code__c, Apttus_Proposal__Proposal__c, Apttus_Proposal__Proposal__r.Id ,Apttus_Proposal__Proposal__r.Apttus_Proposal__Account__c 
                              ,Apttus_Proposal__Product__r.Name, Apttus_QPConfig__AttributeValueId__r.Primary_Zone__c , Apttus_QPConfig__AttributeValueId__r.Secondary_Zone__c 
                                                          from Apttus_Proposal__Proposal_Line_Item__c 
                                                          where Product_Option_Code__c  in :CPQ_Constants.BSAADDENDUMELIGIBLEPRODCUTCODES2  and Apttus_Proposal__Proposal__c in :setFinalizedProposalIds ]; 
                    //System.debug('ar.Apttus_QPConfig__OptionId__r.Name ProposalList' + ProposalList);
                  for (Apttus_Proposal__Proposal_Line_Item__c ar : ProposalList)  {
                      
                      String ProposalID;
                      
                      
                      //Custom_Addend_Link.put(ar.Apttus_Proposal__Proposal__r.Id,ar.Apttus_Proposal__Proposal__r.Apttus_Proposal__Account__r.Custom_Addendum_Link__c);
                      System.debug('ar.Apttus_QPConfig__OptionId__r.Name' + ar.Product_Option_Code__c);
            
                      if(proposalToProductCode.containsKey(ar.Apttus_Proposal__Proposal__c))
                      {
                        List<String> ProductCode = proposalToProductCode.get(ar.Apttus_Proposal__Proposal__c);
                        ProductCode.add(ar.Product_Option_Code__c);
                        proposalToProductCode.put(ar.Apttus_Proposal__Proposal__c,ProductCode);
                      }
                      else
                      {
                           proposalToProductCode.put(ar.Apttus_Proposal__Proposal__c, new List<String> {ar.Product_Option_Code__c});
                      }
                      if(ar.Apttus_QPConfig__AttributeValueId__r.Primary_Zone__c <> null && ar.Apttus_QPConfig__AttributeValueId__r.Secondary_Zone__c <> null )
                      {
                        if(proposalToProductCode.containsKey(ar.Apttus_Proposal__Proposal__c))
                        {
                          List<String> PrimaryZone = proposalToProductCode.get(ar.Apttus_Proposal__Proposal__c);
                          PrimaryZone.add(ar.Product_Option_Code__c+'Zones');
                          proposalToProductCode.put(ar.Apttus_Proposal__Proposal__c,PrimaryZone);
                        }
                        else
                        {
                          proposalToProductCode.put(ar.Apttus_Proposal__Proposal__c, new List<String> {ar.Product_Option_Code__c+'Zones'});
                        }
                      }
                                
                    if(ar.Apttus_Proposal__Proposal__r.Apttus_Proposal__Account__c<>null)
                      AccountIds.add(String.valueOf(ar.Apttus_Proposal__Proposal__r.Apttus_Proposal__Account__c));
                                                  
                  }
                 // System.debug( 'Custom_Link_and_Addendum__c AccountIds ' + AccountIds );
                  List<Custom_Link_and_Addendum__c> cLink = [select id, Relationship_Type__c, Product_Name__r.Name ,Product_Name__c ,Link__c,Account__c  
                                                            from Custom_Link_and_Addendum__c where Link__c!=null AND Account__c in :AccountIds]; 
                  
                  
                          //System.debug( 'Custom_Link_and_Addendum__c demo 2 ' + cLink );
                  if(cLink<>null){
                      for(Custom_Link_and_Addendum__c crLink : cLink)
                      {
                         // System.debug( 'Custom_Link_and_Addendum__c demo 2 ' + CustomLinks );
                          if(CustomLinks.containsKey(String.valueOf(crLink.Account__c)))
                          {
                              List<Custom_Link_and_Addendum__c> cLinkAddendumList = CustomLinks.get(String.valueOf(crLink.Account__c));
                              cLinkAddendumList.add(crLink);
                              CustomLinks.put(String.valueOf(crLink.Account__c),cLinkAddendumList);
                          }
                          else
                          {
                              CustomLinks.put(String.valueOf(crLink.Account__c), new List<Custom_Link_and_Addendum__c> {crLink});
                          }
                      }
                  }
                 //System.debug( 'Custom_Link_and_Addendum__c demo 2333 ' + CustomLinks );
                for( Apttus_Proposal__Proposal__c proposal : newMap.values()){
                    // System.debug( 'Custom_Link_and_Addendum__c demo 2333 ' + proposal.Apttus_Proposal__Account__c );
                    proposal.Box_Relay_BSA_Link__c = CPQ_constants.Box_Relay_BSA_Link ;
                    proposal.Enterprise_Plus_BSA_Link__c = CPQ_constants.Enterprise_Plus_BSA_Link;
                    proposal.Box_KeySafe_BSA_Link__c = CPQ_constants.Box_KeySafe_BSA_Link ;
                    proposal.Box_KeySafe_with_Azure_Key_Link__c = CPQ_constants.BOX_KEYSAFE_AZURE_LINK ;
                    proposal.Box_KeySafe_CloudHSM_BSA_Link__c = CPQ_constants.Box_KeySafe_CloudHSM_BSA_Link ;
                    proposal.Platform_Enterprise_BSA_Link__c = CPQ_constants.Platform_Enterprise_BSA_Link ;
                    proposal.Platform_Keysafe_BSA_Link__c = CPQ_constants.Platform_Keysafe_BSA_Link ;                              
                    proposal.Monthly_Active_Users_BSA_Link__c = CPQ_constants.Monthly_Active_Users_BSA_Link ;                              
                    proposal.Platform_Storage_BSA_Link__c = CPQ_constants.Monthly_Active_Users_BSA_Link ;                              
                    proposal.Monthly_Platform_API_Calls_BSA_Link__c = CPQ_constants.Monthly_Active_Users_BSA_Link ;                              
                    proposal.Monthly_Platform_Bandwidth_BSA_Link__c = CPQ_constants.Monthly_Active_Users_BSA_Link ;                              
                    proposal.Box_Licenses_with_Zones_BSA_Link__c = CPQ_constants.Box_Licenses_with_Zones_BSA_Link ;
                    proposal.Elite_Licences_with_zones__c = CPQ_constants.Elite_Licences_with_zones ;
                    proposal.Platform_View_BSA_Link__c = CPQ_constants.Platform_View_BSA_Link ;
                    proposal.Platform_Zones_BSA_Link__c= CPQ_constants.Platform_Zones_BSA_Link;
                    proposal.Box_Keysafe_Elite_BSA_Link__c= CPQ_constants.Box_Keysafe_Elite_BSA_Link;
                    proposal.Box_Keysafe_Elite_CloudHSM_BSA_Link__c= CPQ_constants.Box_Keysafe_Elite_CloudHSM_BSA_Link;
                    proposal.Platform_Keysafe_CloudHSM_BSA_Link__c= CPQ_constants.Platform_Keysafe_CloudHSM_BSA_Link;
                    proposal.Platform_enterprise_with_keyafe_clause__c = CPQ_constants.setFalse;
                    proposal.Platform_enterpise_with_zones__c = CPQ_constants.setFalse;
                    proposal.Platform_enterprise_with_core_licenses__c = CPQ_constants.setFalse;
                    proposal.Box_Zones_Multi_BSA_Link__c = CPQ_constants.BOX_PLATFORM_ZONES_MULTI;
                    proposal.Custom_Skills_Addendum_link__c  = customSkills.Custom_Skill_Addendum_Link__c;
                    
                    proposal.Enterprise_plus_clause__c = CPQ_constants.setFalse;

                    List<String> lineItemProductCodes = proposalToProductCode.get(proposal.Id);

                    if (lineItemProductCodes<>null) {

                        if (lineItemProductCodes.contains(CPQ_constants.platformEnterpriseCode) 
                            && lineItemProductCodes.contains(CPQ_constants.boxKeysafeAWSKMSPlatformCode)) {
                            
                            proposal.Platform_enterprise_with_keyafe_clause__c = CPQ_constants.setTrue;
                        }
                        if (lineItemProductCodes.contains(CPQ_constants.platformZonesCode ) 
                            && lineItemProductCodes.contains(CPQ_constants.platformEnterpriseCode)) {
                            
                            proposal.Platform_enterpise_with_zones__c = CPQ_constants.setTrue;
                        }
                        if (lineItemProductCodes.contains(CPQ_constants.platformEnterpriseCode)) {
                            
                            proposal.Enterprise_plus_clause__c = CPQ_constants.setTrue;
                        }
                        if ((lineItemProductCodes.contains(CPQ_constants.businessAccountLicenses) 
                                || lineItemProductCodes.contains(CPQ_constants.businessPlusAccountLicensesCode ) 
                                || lineItemProductCodes.contains(CPQ_constants.enterprisePlusCode)) 
                            && lineItemProductCodes.contains(CPQ_constants.platformEnterpriseCode )) {
                            
                            proposal.Platform_enterprise_with_core_licenses__c = CPQ_constants.setTrue; 
                        }
                    }
                    if (proposal.Apttus_Proposal__Account__c <> null 
                        && CustomLinks.containsKey(proposal.Apttus_Proposal__Account__c)
                        && CustomLinks.get(proposal.Apttus_Proposal__Account__c) <> null) {
                        
                        for (Custom_Link_and_Addendum__c cLinkvalue : CustomLinks.get(proposal.Apttus_Proposal__Account__c)) {

                            if (cLinkvalue.Relationship_Type__c.equalsIgnoreCase(CPQ_Constants.CUSTOM_BSA)) {
                                if (cLinkvalue.Link__c <> null) {
                                    proposal.Custom_BSA_Link__c = cLinkvalue.Link__c;
                                }
                            }
                            else if (lineItemProductCodes <> null
                                && cLinkvalue.Link__c <> null
                                && cLinkvalue.Product_Name__r.Name <> null) {

                                if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.boxRelay) 
                                    && lineItemProductCodes.contains(CPQ_constants.boxRelayCodeCode)){

                                    proposal.Box_Relay_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.boxRelayPartialDeployment) 
                                    && lineItemProductCodes.contains(CPQ_constants.boxRelayPartialDeploymentCode )){

                                    proposal.Box_Relay_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.boxKeysafeAWSKMS)
                                    && lineItemProductCodes.contains(CPQ_constants.boxKeysafeAWSKMSCode)){

                                    proposal.Box_KeySafe_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.boxKeysafeAWSCloudHSM) 
                                    && lineItemProductCodes.contains(CPQ_constants.boxKeysafeAWSCloudHSMCode)){

                                    proposal.Box_KeySafe_CloudHSM_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.boxKeysafeAWSKMSElite)
                                    && lineItemProductCodes.contains(CPQ_constants.boxKeysafeAWSKMSEliteCode )){

                                    proposal.Box_Keysafe_Elite_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.boxKeysafeAWSCloudHSMElite )
                                    && lineItemProductCodes.contains(CPQ_constants.boxKeysafeAWSCloudHSMEliteCode )){

                                    proposal.Box_Keysafe_Elite_CloudHSM_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.enterprisePlus) 
                                    && lineItemProductCodes.contains(CPQ_constants.enterprisePlusCode)){

                                    proposal.Enterprise_Plus_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.platformEnterprise) 
                                    && lineItemProductCodes.contains(CPQ_constants.platformEnterpriseCode)){

                                    proposal.Platform_Enterprise_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.monthlyActiveUsers) 
                                    && lineItemProductCodes.contains(CPQ_constants.monthlyActiveUsersCode)){

                                    proposal.Monthly_Active_Users_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.enterpriseAccountLicenses) 
                                    && lineItemProductCodes.contains(CPQ_constants.enterpriseAccountLicensesCode)){

                                    proposal.Box_Licenses_with_Zones_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.businessPlusAccountLicenses) 
                                    && lineItemProductCodes.contains(CPQ_constants.businessPlusAccountLicensesZonesCode)){

                                    proposal.Box_Licenses_with_Zones_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.eliteAccountLicenses) 
                                    && lineItemProductCodes.contains(CPQ_constants.eliteAccountLicensesCode)){

                                    proposal.Elite_Licences_with_zones__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.platformView) 
                                    && lineItemProductCodes.contains(CPQ_constants.platformViewCode)){

                                    proposal.Platform_View_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.platformZones ) 
                                    && lineItemProductCodes.contains(CPQ_constants.platformZonesCode )){

                                    proposal.Platform_Zones_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.boxKeysafeAWSCloudHSMPlatform ) 
                                    && lineItemProductCodes.contains(CPQ_constants.boxKeysafeAWSCloudHSMPlatformCode)){

                                    proposal.Platform_Keysafe_CloudHSM_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.boxKeysafeAWSKMSPlatform) 
                                    && lineItemProductCodes.contains(CPQ_constants.boxKeysafeAWSKMSPlatformCode) ){

                                    proposal.Platform_Keysafe_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.monthlyPlatformAPI) 
                                    && lineItemProductCodes.contains(CPQ_constants.monthlyPlatformAPICode) ){

                                    proposal.Monthly_Platform_API_Calls_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.platformStorage ) 
                                    && lineItemProductCodes.contains(CPQ_constants.platformStorageCode) ){

                                    proposal.Platform_Storage_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.platformBandwidth) 
                                    && lineItemProductCodes.contains(CPQ_constants.platformBandwidthCode) ){

                                    proposal.Monthly_Platform_Bandwidth_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if ((cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.BOX_ZONES_MULTI_NAME) 
                                        && lineItemProductCodes.contains(CPQ_constants.BOX_MULTI_ZONES_CODE)) 
                                    || (cLinkvalue.Product_Name__r.Name.equalsIgnoreCase(CPQ_constants.BOX_PLATFORM_ZONES_MULTI_NAME) 
                                        && lineItemProductCodes.contains(CPQ_constants.BOX_PLATFORM_MULTI_ZONES_CODE))) {

                                    proposal.Box_Zones_Multi_BSA_Link__c = cLinkvalue.Link__c;
                                }
                                else if ((cLinkvalue.Product_Name__r.ProductCode.equalsIgnoreCase(CPQ_constants.CUSTOM_SKILLS_CODE)  
                                    && lineItemProductCodes.contains(CPQ_constants.CUSTOM_SKILLS_CODE))) {

                                    proposal.Custom_Skills_Addendum_link__c = cLinkvalue.Link__c;
                                }
                                
                            }
                        }
                    }
                } 
            }
            catch(Exception ex)  {
                SystemMessage.log( 'CPQ_ProposalTriggerHelper method setCustomAddendumLinkOnFinalization failed', ex );
                System.debug(ex.getMessage());
            }    
        }
    }    
      
      //Added by Abhishek Awasthi: JIRA BC-817
    public static void QuoteApprovalCount(Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap){
            Try
            {
                Set<ID> proposalIds = new Set<ID>();
                Profile ProfileName = [select Name from profile where id = :userinfo.getProfileId()];
                if(ProfileName.Name=='Box: Sales Ops'){
                    for(Apttus_Proposal__Proposal__c proposalSO : newMap.values()) {
                        for(Schema.FieldSetMember f : SObjectType.Apttus_Proposal__Proposal__c.FieldSets.channel_Revision.getFields()) {
                            String fieldName = f.getFieldPath();
                            if(oldMap.get(proposalSO.Id).get(fieldName) != proposalSO.get(fieldName))
                            {
                                system.debug('@@ field name   :-- '+ fieldName);
                                if(proposalSO.Quote_Revision_Index__c<>null)
                                    proposalSO.Quote_Revision_Index__c += 1;
                                else 
                                    proposalSO.Quote_Revision_Index__c = 0;
                            }
                            
                        }
                    }
                }
                
            }
            catch(Exception ex)  {
                SystemMessage.log( 'CPQ_ProposalTriggerHelper method QuoteApprovalCount failed', ex );
                System.debug(ex.getMessage());
            }   
          
    }
    
    public static void assignQuoteIdToAccLoc(List<Apttus_Proposal__Proposal__c> listNewProposal, Map<Id,Apttus_Proposal__Proposal__c> mapOldProposal) {
        
        list<Apttus_Proposal__Proposal__c> proposalList = new list<Apttus_Proposal__Proposal__c>();
        set<Id> accLocationIds = new set<Id>();
        Map<Id,Apttus_Config2__AccountLocation__c> accLocationMap = new Map<Id,Apttus_Config2__AccountLocation__c>();
        Currency_Exchange_Rates__c currencySO;
        
        try {
            for(Apttus_Proposal__Proposal__c proposalSO : listNewProposal) {
                if(proposalSO.Apttus_Proposal__Approval_Stage__c <> null && proposalSO.Apttus_Proposal__Approval_Stage__c <> mapOldProposal.get(proposalSO.Id).Apttus_Proposal__Approval_Stage__c 
                    && proposalSO.Apttus_Proposal__Approval_Stage__c == CPQ_constants.Accepted && proposalSO.Apttus_QPConfig__LocationId__c <> null) {
                    
                    accLocationIds.add(proposalSO.Apttus_QPConfig__LocationId__c);
                    proposalList.add(proposalSO);
                }
            }
            if(accLocationIds.size()>0) {
                accLocationMap = new Map<Id,Apttus_Config2__AccountLocation__c>([SELECT Id,Quote_Id__c,Payment_Frequency__c,Price_List_Id__c,CurrencyIsoCode,Account_Type_Sold_renewal__c,Core_ARR__c,Core_NRR__c,
                                                                        Platform_ARR__c,Platform_NRR__c,KeySafe_ARR__c,Box_Consulting_ARR__c,Core_Seat_Quantity__c,Platform_Seat_Quantity__c,Relay_ARR__c,Is_Auto_renew_removed__c,
                                                                        Platform_BC_NRR__c,Governance_ARR__c,GxP_ARR__c,Total_ARR__c, Total_Net_Arr__c FROM Apttus_Config2__AccountLocation__c WHERE Id IN : accLocationIds]);
                currencySO = Currency_Exchange_Rates__c.getInstance();
            }
            for(Apttus_Proposal__Proposal__c proposalSO : proposalList) {
                Apttus_Config2__AccountLocation__c accLocationSO = accLocationMap.get(proposalSO.Apttus_QPConfig__LocationId__c);
                if(proposalSO.CurrencyIsoCode <> accLocationMap.get(proposalSO.Apttus_QPConfig__LocationId__c).CurrencyIsoCode) {
                    Decimal conversionRate = (Decimal) currencySO.get(accLocationMap.get(proposalSO.Apttus_QPConfig__LocationId__c).CurrencyIsoCode+'_to_'+proposalSO.CurrencyIsoCode+'__c');
                    
                    accLocationSO.Core_ARR__c = accLocationSO.Core_ARR__c<>null?accLocationSO.Core_ARR__c*conversionRate:null;
                    accLocationSO.Core_NRR__c = accLocationSO.Core_NRR__c<>null?accLocationSO.Core_NRR__c*conversionRate:null;
                    accLocationSO.Platform_ARR__c = accLocationSO.Platform_ARR__c<>null?accLocationSO.Platform_ARR__c*conversionRate:null;
                    accLocationSO.Platform_NRR__c = accLocationSO.Platform_NRR__c<>null?accLocationSO.Platform_NRR__c*conversionRate:null;
                    accLocationSO.KeySafe_ARR__c = accLocationSO.KeySafe_ARR__c<>null?accLocationSO.KeySafe_ARR__c*conversionRate:null;
                    accLocationSO.Box_Consulting_ARR__c = accLocationSO.Box_Consulting_ARR__c<>null?accLocationSO.Box_Consulting_ARR__c*conversionRate:null;
                    accLocationSO.Core_Seat_Quantity__c = accLocationSO.Core_Seat_Quantity__c<>null?accLocationSO.Core_Seat_Quantity__c*conversionRate:null;
                    accLocationSO.Platform_Seat_Quantity__c = accLocationSO.Platform_Seat_Quantity__c<>null?accLocationSO.Platform_Seat_Quantity__c*conversionRate:null;
                    accLocationSO.Relay_ARR__c = accLocationSO.Relay_ARR__c<>null?accLocationSO.Relay_ARR__c*conversionRate:null;
                    accLocationSO.Platform_BC_NRR__c = accLocationSO.Platform_BC_NRR__c<>null?accLocationSO.Platform_BC_NRR__c*conversionRate:null;
                    accLocationSO.Governance_ARR__c = accLocationSO.Governance_ARR__c<>null?accLocationSO.Governance_ARR__c*conversionRate:null;
                    accLocationSO.GxP_ARR__c = accLocationSO.GxP_ARR__c<>null?accLocationSO.GxP_ARR__c*conversionRate:null;
                    accLocationSO.Total_ARR__c = accLocationSO.Total_ARR__c<>null?accLocationSO.Total_ARR__c*conversionRate:null;
                    accLocationSO.Total_Net_ARR__c = accLocationSO.Total_Net_ARR__c<>null?accLocationSO.Total_Net_ARR__c*conversionRate:null;
                }
                accLocationSO.Id = proposalSO.Apttus_QPConfig__LocationId__c;
                accLocationSO.Quote_Id__c = proposalSO.Id;
                accLocationSO.Price_List_Id__c = proposalSO.Apttus_QPConfig__PriceListId__c;
                accLocationSO.CurrencyIsoCode = proposalSO.CurrencyIsoCode;
                accLocationSO.Account_Type_Sold_renewal__c = proposalSO.Account_Type_Sold__c;
                accLocationSO.Auto_Renew_EID__c = proposalSO.Stop_Auto_Renewal__c;
                if(proposalSO.Quote_Type__c == CPQ_constants.NEWVAR || proposalSO.Quote_Type__c == CPQ_constants.RESTART || proposalSO.Quote_Type__c == CPQ_constants.RENEWAL)
                    accLocationSO.Is_Auto_renew_removed__c = proposalSO.Is_Auto_renew_removed__c;
                if(proposalSO.Quote_Type__c <> CPQ_Constants.RENEWAL || (proposalSO.Quote_Type__c == CPQ_Constants.RENEWAL && 
                    (proposalSO.Non_Standard_Term__c == null || proposalSO.Non_Standard_Term__c == 0)))
                    accLocationSO.Payment_Frequency__c = proposalSO.Payment_Frequency__c;
            }

            if(accLocationMap.keySet().size()>0)
                    update accLocationMap.values();
        } catch(Exception ex){
            SystemMessage.log( 'CPQ_ProposalTriggerHelper method assignQuoteIdToAccLoc failed', ex );
            System.debug('get message : '+ex.getMessage() + ' get line number ' + ex.getLineNumber());
        }
    }
    //Added by Shivani Rathod: JIRA BC- 1034  (custom link will be assigned from proposal to opportunity)
    public static void assignContractLink(List<Apttus_Proposal__Proposal__c> listNewProposal, Map<Id,Apttus_Proposal__Proposal__c> mapOldProposal) {
        try {
            map<Id,opportunity> opportunityMap = new map<Id,opportunity>();
            for(Apttus_Proposal__Proposal__c proposalSO : listNewProposal) {
                if(proposalSO.Apttus_Proposal__Primary__c && proposalSO.Link_To_Contract__c <> null && proposalSO.Link_To_Contract__c <> mapOldProposal.get(proposalSO.Id).Link_To_Contract__c && !opportunityMap.containsKey(proposalSO.Apttus_Proposal__Opportunity__c)) {
                    opportunity opportunitySO = new opportunity();
                    opportunitySO.Id = proposalSO.Apttus_Proposal__Opportunity__c;
                    opportunitySO.Link_To_Contract__c = proposalSO.Link_To_Contract__c;
                    opportunityMap.put(opportunitySO.Id,opportunitySO);
                }
            }
            
            if(opportunityMap.keySet().size()>0 && CPQ_Constants.IS_OPP_SYNC_ENABLED)
                update opportunityMap.values();
        } catch(Exception ex){
            SystemMessage.log( 'CPQ_ProposalTriggerHelper method assignContractLink failed', ex );
            System.debug('get message : '+ex.getMessage() + ' get line number ' + ex.getLineNumber());
        }
    }
    
    //JIIRA: BC-1009, calculating the selling term and the expected end date for different quote types
    public static void calculateEndDate(List<Apttus_Proposal__Proposal__c> listNewProposal, Map<Id,Apttus_Proposal__Proposal__c> mapOldProposal) {
        
        for(Apttus_Proposal__Proposal__c proposalSO : listNewProposal) { 
        
             if(proposalSO.Quote_Term__c <> null && proposalSO.Quote_Term__c <> mapOldProposal.get(proposalSO.Id).Quote_Term__c){ 
                proposalSO.Non_Standard_Term__c=null;
             }

            if(proposalSO.Apttus_Proposal__ExpectedStartDate__c <> mapOldProposal.get(proposalSO.Id).Apttus_Proposal__ExpectedStartDate__c && (proposalSO.Quote_Type__c == CPQ_constants.Upsell || proposalSO.Quote_Type__c == CPQ_constants.Cancellation)) {
                proposalSO.Contract_Term__c = Apttus_Config2.CPQWebService.computeTerm(proposalSO.Apttus_Proposal__ExpectedStartDate__c,proposalSO.Apttus_Proposal__ExpectedEndDate__c, CPQ_Constants.MONTHLY_FREQUENCY);
            }
            else if(proposalSO.Non_Standard_Term__c <> null) {
                proposalSO.Apttus_Proposal__ExpectedEndDate__c = proposalSO.Apttus_Proposal__ExpectedStartDate__c.addMonths(Integer.valueOf(proposalSO.Non_Standard_Term__c))-1;
                proposalSO.Contract_Term__c = proposalSO.Non_Standard_Term__c;
            }
            else if(proposalSO.Quote_Term__c <> null){
                Integer QuoteTerm = Integer.valueOf(proposalSO.Quote_Term__c);
                proposalSO.Apttus_Proposal__ExpectedEndDate__c = proposalSO.Apttus_Proposal__ExpectedStartDate__c.addMonths(QuoteTerm)-1;
                proposalSO.Contract_Term__c = QuoteTerm;
            }

            //start BC-3417
            if(proposalSO.Overage_Type__c <> null && proposalSO.Overage_Type__c <> mapOldProposal.get(proposalSO.Id).Overage_Type__c && proposalSO.Overage_Type__c == CPQ_Constants.PRODUCT_GROUP_FULL) {
                if(proposalSO.Overage_Start_Date__c == null)
                    proposalSO.Overage_Start_Date__c = proposalSO.Apttus_Proposal__ExpectedStartDate__c;
                if(proposalSO.Overage_End_Date__c == null)
                    proposalSO.Overage_End_Date__c = proposalSO.Apttus_Proposal__ExpectedEndDate__c;
            }
            //End BC-3417

            //UAT defect, if the custom signed has a value then change the stage to 'Fully Signed'
            if(proposalSO.Customer_Sign_Date__c <> mapOldProposal.get(proposalSO.Id).Customer_Sign_Date__c && proposalSO.Customer_Sign_Date__c <> null) {
                proposalSO.Is_fully_Signed__c = true;
                proposalSO.Apttus_Proposal__Approval_Stage__c = CPQ_constants.BOX_PROPOSAL_APPROVAL_FULLY_SIGNED;

            }

        }
    }
    
    
    //JIIRA: BC-1015, Determine Quote type and Revenue
   public static void setOpportunitySubscriptionType(Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap){
        
        set<Id> setFinalizedProposalIds = new set<Id>();
        for(Apttus_Proposal__Proposal__c proposal : newMap.values()) {
            if(((oldMap.get(proposal.Id)).Apttus_QPConfig__ConfigurationFinalizedDate__c == null
                && proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != null)
               || 
               (oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != null
                && oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c) ) {
                    
                        setFinalizedProposalIds.add(proposal.Id);
                    
            }
        }            
        if(setFinalizedProposalIds.size() > 0){

            try {

                set<Id> quoteIds = new set<Id>();

                for(Apttus_Proposal__Proposal_Line_Item__c lineSO : [Select id, Apttus_Proposal__Proposal__c,Incremental_Quantity__c from Apttus_Proposal__Proposal_Line_Item__c where Apttus_Proposal__Proposal__c in :setFinalizedProposalIds]) {

          if(lineSO.Incremental_Quantity__c<0) {
            quoteIds.add(lineSO.Apttus_Proposal__Proposal__c);
          }
        }

        for(Apttus_Proposal__Proposal__c app : newMap.values()) {
          if(quoteIds.contains(app.Id) && (app.Quote_Type__c == CPQ_constants.Upsell || app.Quote_Type__c == CPQ_constants.Renewal)) {
            app.Opportunity_Subscription_Type__c = app.Quote_Type__c + ' - Churn';
          }
          else {
            app.Opportunity_Subscription_Type__c = app.Quote_Type__c;
          }

        }                       
              }
              catch(Exception ex)  {
                    SystemMessage.log( 'CPQ_ProposalTriggerHelper method setOpportunitySubscriptionType failed', ex );
                    System.debug(ex.getMessage());
              }   
        }
    }

     //Added by shivani for jira 1022 1023
    public static void setDefaulFieldsRenewal2(List<Apttus_Proposal__Proposal__c> newMap) {
        Map<String,String> mapProposalToOriginalProposal = new  Map<String,String>();
        Map<Id,Id> mapProposalToConfig = new Map<Id,Id>();
        Map<Id,Id> mapConfigToTempRenew = new Map<Id,Id>();
        List<String> originalName = new List<String>();
        List<String> originalProposalList = new List<String>();
        String queryAccountLocation;
        Map<String,Apttus_Config2__AccountLocation__c> proposalToLocation = new Map<String,Apttus_Config2__AccountLocation__c>();
        String queryProposal;
        Map<String,Apttus_Proposal__Proposal__c> mapProposalNametoProposal = new Map<String,Apttus_Proposal__Proposal__c>();
        //Start BC:4192 - Shikha Dave
        Map<String,Apttus_Config2__AccountLocation__c> proposalToLocationLegacy = new Map<String,Apttus_Config2__AccountLocation__c>();
        //End BC:4192
        Set<String> locationIds = new Set<String>();
        Map<Id, String> proposalIdToLocationId = new Map<Id, String>();

            for( Apttus_Proposal__Proposal__c proposal : newMap ) {
                System.debug(' in setDefaulFieldsRenewal2 Apttus_QPConfig__IsSystemGenerated__c  ' + proposal.Apttus_QPConfig__IsSystemGenerated__c);
               
                if ( proposal.Apttus_QPConfig__IsSystemGenerated__c ) {

                    String proposalName = proposal.Apttus_Proposal__Proposal_Name__c;
                     
                    if ( proposalName != null ) {
                        // delimiters
                        String colon  = ':';
                        String hyphen = '-';
                        // identifiers
                        String proposalNamePrefix = 'Q-';
                        String locationKeyPrefix = Apttus_Config2__AccountLocation__c.sobjecttype.getDescribe().getKeyPrefix();

                        String parsedVal;

                        // get the previous proposal name from the name
                        // ex: Renew:Q-00024633-aCL2D00000006AiWAI-11/7/2019 => Q-00024633
                        if ( proposalName.contains( proposalNamePrefix ) ) {
                            parsedVal = proposalName.substringAfter( colon ).substringBeforeLast( hyphen ).substringBeforeLast( hyphen );

                            // map of proposal name to previous proposal name
                            mapProposalToOriginalProposal.put( proposalName, parsedVal );
                            originalName.add( parsedVal );
                        }
                        // otherwise get the account location id from the name
                        // ex: Renew:-aCL2D0000005PzSWAU-8/5/2020 => aCL2D0000005PzSWAU
                        else if ( proposalName.contains( locationKeyPrefix ) ) {
                            parsedVal = proposalName.substringBetween( hyphen, hyphen );

                            locationIds.add( parsedVal );
                            proposalIdToLocationId.put( proposal.Id, parsedVal );
                        }
                    }
                }
            }

            System.debug('locationIds: '+locationIds);
            System.debug(' in setDefaulFieldsRenewal  mapProposalToOriginalProposal ' + mapProposalToOriginalProposal);
            
            if ( mapProposalToOriginalProposal.size() > 0 || proposalIdToLocationId.size() > 0 ) {
                try {

                    Id ChannelExistingRecordType = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Channel - Existing').getRecordTypeId(); 
                    Id DirectExistingRecordType = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Direct - Existing').getRecordTypeId(); 

                    //List<Renewal_settings__c> customSettings = [select id,Account_Location_API_name_for_renewal__c,Opportunity_API_name_for_renewal__c,Quote_field_API_name_for_renwal__c from Renewal_settings__c];
                    List<Schema.FieldSetMember> quoteField = SobjectType.Apttus_Proposal__Proposal__c.FieldSets.getMap().get('renewal_quote').getFields();
                     //for(Schema.FieldSetMember renewalFields : fs1)
                     //     System.debug(' demo fieldset ' + renewalFields.getFieldPath());

                    for(Schema.FieldSetMember renewalFields : quoteField)
                    {
                      if(queryProposal<>null)
                      {
                        queryProposal += ',';
                      queryProposal += renewalFields.getFieldPath();
                      }
                       else
                          queryProposal = renewalFields.getFieldPath();
                    }
                    String soqlQuery = 'Select Name,Apttus_Proposal__Payment_Term__c,Payment_Frequency__c,' + queryProposal + ' from Apttus_Proposal__Proposal__c where Name in :originalName';
                    System.debug(' soqlQuery demo ' + soqlQuery);
                    List<Apttus_Proposal__Proposal__c> originalProposals = Database.query(soqlQuery);
                    for(Apttus_Proposal__Proposal__c originalProposal : originalProposals)
                    {
                      mapProposalNametoProposal.put(originalProposal.Name,originalProposal);
                      originalProposalList.add(originalProposal.Name);
                       
                    }

                    List<Schema.FieldSetMember> accLocationField = SobjectType.Apttus_Proposal__Proposal__c.FieldSets.getMap().get('Renewal_field_from_Account_Location').getFields();
                    
                    for(Schema.FieldSetMember renewalFields : accLocationField)
                    {
                      if(queryAccountLocation<>null)
                      {
                        queryAccountLocation += ',';
                      queryAccountLocation += renewalFields.getFieldPath();
                      }
                       else
                          queryAccountLocation = renewalFields.getFieldPath();
                    }

                     soqlQuery = 'Select Name,Quote_Id__r.Name,SoldTo_Contact__c,Start_Date__c,End_Date__c,BillTo_Contact__c,Payment_Term_x__c,Total_ARR__c,Core_Seat_Quantity__c,Platform_Seat_Quantity__c,Contract_Term__c,Payment_Method_x__c,' + 
                                  'Account_Type_Sold_renewal__c,Is_Auto_renew_removed__c,Total_Net_ARR__c, Box_Enterprise_Id__c, ' + queryAccountLocation + ' from Apttus_Config2__AccountLocation__c where Quote_Id__r.Name in :originalProposalList';
                    System.debug(' soqlQuery demo ' + soqlQuery);

                    List<Apttus_Config2__AccountLocation__c> originalLocation = Database.query(soqlQuery);
                    for(Apttus_Config2__AccountLocation__c location : originalLocation)
                        proposalToLocation.put(location.Quote_Id__r.Name,location);

                    //Start BC:4192 - Shikha Dave
                    if ( locationIds.size() > 0 ) {

                        soqlQuery = 'Select Name,Quote_Id__r.Name,SoldTo_Contact__c,Start_Date__c,End_Date__c,BillTo_Contact__c,Payment_Term_x__c,Total_ARR__c,Core_Seat_Quantity__c,Platform_Seat_Quantity__c,Contract_Term__c,Payment_Method_x__c,Is_Auto_renew_removed__c,' + 
                                  'Account_Type_Sold_renewal__c, Renewal_Opportunity__c, Is_channel__c, Zuora_Subscription_Number__c, Apttus_Config2__AccountId__c, CurrencyIsoCode, Past_Due_Balance__c,Total_Net_ARR__c, Box_Enterprise_Id__c, ' + queryAccountLocation + ' from Apttus_Config2__AccountLocation__c where Id in :locationIds';
                        System.debug(' soqlQuery location ' + soqlQuery);

                        List<Apttus_Config2__AccountLocation__c> originalLocationLegacy = Database.query(soqlQuery);

                        for ( Apttus_Config2__AccountLocation__c location : originalLocationLegacy ) {
                            proposalToLocationLegacy.put( location.Id, location) ;
                        }
                    }

                    //End BC:4192
                    System.debug('proposalToLocationLegacy: '+proposalToLocationLegacy);
                    System.debug(' in setDefaulFieldsRenewal  mapProposalToOriginalProposal demo2 ' + mapProposalNametoProposal);
                    
                    for( Apttus_Proposal__Proposal__c proposal : newMap ) {

                        String proposalName = proposal.Apttus_Proposal__Proposal_Name__c;
                        String locationId   = proposalIdToLocationId.containsKey( proposal.Id ) 
                                                ? proposalIdToLocationId.get( proposal.Id ) 
                                                    : null;

                        if ( proposal.Apttus_QPConfig__IsSystemGenerated__c ) {
                            proposal.Quote_Type__c = CPQ_constants.Renewal;

                            System.debug('legacy: '+proposalToLocationLegacy.containsKey( locationId ) );
                            System.debug('Auto: '+proposalToLocation.get(mapProposalToOriginalProposal.get(proposalName)));

                            String previousProposalName                   = mapProposalToOriginalProposal.get( proposalName );
                            Apttus_Proposal__Proposal__c previousProposal = mapProposalNametoProposal.containsKey( previousProposalName )
                                                                                ? mapProposalNametoProposal.get( previousProposalName )
                                                                                    : null;
                            Apttus_Config2__AccountLocation__c location   = proposalToLocation.containsKey( previousProposalName )
                                                                                ? proposalToLocation.get( previousProposalName )
                                                                                    : null;

                            if ( location <> null ) {

                                proposal.Apttus_Proposal__ExpectedStartDate__c = location.End_Date__c.addDays(1);
                                proposal.Apttus_Proposal__ExpectedEndDate__c   = ((location.End_Date__c).addMonths(Integer.valueOf(location.Contract_Term__c))).addDays(-1);
                                proposal.Sold_To_Contact__c                    = location.SoldTo_Contact__c;
                                proposal.Bill_To_Contact__c                    = location.BillTo_Contact__c;
                                proposal.Apttus_Proposal__Payment_Term__c      = location.Payment_Term_x__c;
                                proposal.Pre_Renewal_Renewal_Amount__c         = location.Total_Net_ARR__c;
                                proposal.Payment_Method__c                     = location.Payment_Method_x__c;
                                proposal.Quote_Term__c                         = String.valueOf(location.Contract_Term__c);
                                proposal.Is_Auto_renew_removed__c              = location.Is_Auto_renew_removed__c;
                                proposal.Pre_Renewal_Contract_Term__c          = location.Contract_Term__c;
                                
                                // account type sold
                                if ( location.Account_Type_Sold_renewal__c<>null ) {
                                    proposal.Pre_Renewal_Account_Type_Sold__c = location.Account_Type_Sold_renewal__c;
                                }
                                
                                // pre-renewal seats sold from core seat qty
                                if ( location.Core_Seat_Quantity__c<>null 
                                     && location.Core_Seat_Quantity__c>0 ) {
                            
                                    proposal.Pre_Renewal_Seats_Sold__c = location.Core_Seat_Quantity__c;
                                }
                                // pre-renewal seats sold from platform seat qty
                                else if ( location.Platform_Seat_Quantity__c<>null 
                                          && location.Platform_Seat_Quantity__c>0 ) {
                                    proposal.Pre_Renewal_Seats_Sold__c = location.Platform_Seat_Quantity__c;
                                }
                                // pre-renewal renewal date
                                if ( location.End_Date__c<>null ) {
                                    proposal.Renewal_Date_Renewals__c = location.End_Date__c.addDays(1);
                                }

                                // values from previous quote
                                if ( previousProposal<>null ) {
                                    proposal.Previous_Payment_Term__c      = previousProposal.Apttus_Proposal__Payment_Term__c;
                                    proposal.Previous_Payment_Frequency__c = previousProposal.Payment_Frequency__c;
                                    proposal.Quote_Origin__c               = CPQ_ProductConstants.QUOTE_ORIGIN_PROPOSAL;
                                    proposal.Quote_Origin_Id__c            = previousProposal.Id;
                                
                                    System.debug('Channel Partner: '+previousProposal.Channel_Partner__c);
                                    if ( previousProposal.Channel_Partner__c==null ) {
                                        proposal.Channel_Partner__c = null;
                                    }
                                }

                                if ( proposal.Is_Channel__c && ChannelExistingRecordType<>null) {
                                    proposal.RecordTypeId = ChannelExistingRecordType;
                                }
                                else if ( DirectExistingRecordType<>null ) {
                                    proposal.RecordTypeId = DirectExistingRecordType;
                                }

                                // field defaulting from previous quote
                                for ( Schema.FieldSetMember renewalFields : quoteField ) {
                                    System.debug(' in setDefaulFieldsRenewal  mapProposalToOriginalProposal demo 3 ' + renewalFields.getFieldPath());
                                    
                                    if ( previousProposal.get( renewalFields.getFieldPath() )<>null ) {
                                        proposal.put(
                                            renewalFields.getFieldPath(),
                                            previousProposal.get(
                                                renewalFields.getFieldPath() 
                                            ) 
                                        );

                                        System.debug(' in setDefaulFieldsRenewal  mapProposalToOriginalProposal demo 4 ');
                                    }
                                }

                                // field defaulting from account location
                                for ( Schema.FieldSetMember renewalFields : accLocationField ) {
                                        
                                    if ( location.get(renewalFields.getFieldPath())<>null ) {
                                        proposal.put(
                                            renewalFields.getFieldPath(),
                                            location.get( 
                                                renewalFields.getFieldPath() 
                                            ) 
                                        );
                                        
                                        System.debug(' in setDefaulFieldsRenewal  mapProposalToOriginalProposal demo 4 ' + proposal.get(renewalFields.getFieldPath()));
                                    }
                                }
                            }
                            //Start BC:4192 To populate fields on legacy Quote: added by Shikha Dave
                            else if ( locationId != null
                                      && proposalToLocationLegacy.containsKey( locationId ) ) {
                            
                                isLegacyOppty = true;

                                location = proposalToLocationLegacy.get( locationId );
                                
                                // channel proposal
                                if ( location.Is_channel__c ) {
                                    proposal.RecordTypeId              = ChannelExistingRecordType;
                                    proposal.Deal_Registration_Type__c = CPQ_Constants.DEAL_REGISTERED;
                                    proposal.Is_Channel__c             = true;

                                }
                                // direct proposal
                                else {
                                    proposal.RecordTypeId = DirectExistingRecordType;
                                }

                                // set proposal name
                                if ( location.Zuora_Subscription_Number__c.length() <= 240 ) {
                                    proposal.Apttus_Proposal__Proposal_Name__c = location.Zuora_Subscription_Number__c + '-renewal';
                                }
                                // truncate proposal name
                                else {
                                    String proposalNameLegacy = location.Zuora_Subscription_Number__c.substring(0,240);
                                    proposal.Apttus_Proposal__Proposal_Name__c = proposalNameLegacy + '-renewal';
                                }
                               // proposal.Apttus_Proposal__Opportunity__c        = location.Renewal_Opportunity__c;
                                proposal.Apttus_Proposal__ExpectedStartDate__c  = location.End_Date__c + 1;
                                proposal.Apttus_Proposal__ExpectedEndDate__c    = location.End_Date__c.addMonths((Integer)location.Contract_Term__c).addDays(-1);
                                proposal.Sold_To_Contact__c                     = location.SoldTo_Contact__c;
                                proposal.Bill_To_Contact__c                     = location.BillTo_Contact__c;
                                proposal.Apttus_Proposal__Payment_Term__c       = location.Payment_Term_x__c;
                                // ESYS-11630 Pre Renewal amounts should be based off NET
                                //proposal.Pre_Renewal_Renewal_Amount__c = location.Total_ARR__c;
                                proposal.Pre_Renewal_Renewal_Amount__c          = location.Total_Net_ARR__c;
                                proposal.Payment_Method__c                      = location.Payment_Method_x__c;
                                proposal.Pre_Renewal_Account_Type_Sold__c       = location.Account_Type_Sold_renewal__c;
                                proposal.Pre_Renewal_Contract_Term__c           = location.Contract_Term__c;
                                proposal.Is_Auto_renew_removed__c               = location.Is_Auto_renew_removed__c;
                                proposal.Renewal_Date_Renewals__c               = location.End_Date__c + 1;
                                proposal.Previous_Payment_Term__c               = location.Payment_Term_x__c;
                                proposal.Previous_Payment_Frequency__c          = location.Payment_Frequency__c;
                                proposal.Apttus_QPConfig__LocationId__c         = location.Id;
                                proposal.Sold_To_Account__c                     = location.Apttus_Config2__AccountId__c;
                                proposal.CurrencyIsoCode                        = location.CurrencyIsoCode;
                                proposal.Quote_Term__c                          = String.valueOf(location.Contract_Term__c);
                                proposal.Bill_To_Account_Balance_Due__c         = location.Past_Due_Balance__c;
                                proposal.Payment_Frequency__c                   = location.Payment_Frequency__c;
                                proposal.Box_Enterprise_ID__c                   = location.Box_Enterprise_Id__c;
                                proposal.Quote_Origin__c                        = CPQ_ProductConstants.QUOTE_ORIGIN_ORDER;

                                if ( location.Core_Seat_Quantity__c != null 
                                     || location.Core_Seat_Quantity__c > 0 ) {
                                    proposal.Pre_Renewal_Seats_Sold__c = location.Core_Seat_Quantity__c;
                                }
                                else if ( location.Platform_Seat_Quantity__c != null 
                                          || location.Platform_Seat_Quantity__c > 0 ) {
                                    proposal.Pre_Renewal_Seats_Sold__c = location.Platform_Seat_Quantity__c;
                                }

                            }
                            //End BC:4192
                        }
                    }
                }

                catch( Exception ex )  {
                    SystemMessage.log( 'CPQ_ProposalTriggerHelper method setDefaulFieldsRenewal2 failed', ex );
                    System.debug( ex.getMessage() + ' line number ' + ex.getLineNumber() );
                } 
            }
    }

   //Added by shivani for jira 1022 1023
    public static void setOpportunityFieldsRenewal(Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap) {
        //System.debug(' in setDefaulFieldsRenewal setOpportunityFieldsRenewal  ' );
      List<String> setRenewalOpportunity = new  List<String>();
      List<String> originalName = new  List<String>();
      List<String> originalOpportunityRenew = new  List<String>();
      Map<String,Id> originalOpportunityRenewMap = new  Map<String,Id>();
      Map<Id,Opportunity> originalOppMap = new Map<Id,Opportunity>();
      Map<Id,Opportunity> renewOppMap = new Map<Id,Opportunity>();
      Map<Id,Apttus_Proposal__Proposal__c> mapProosalToOriginal = new Map<Id,Apttus_Proposal__Proposal__c>();
      String queryOpp;
      Integer startIndex;
      String queryOriginalOpp;
      String originalProposalName;
      Map<Id,String> setAccountLocationIds = new Map<Id,String>();
      Map<String,Apttus_Proposal__Proposal__c> renewQuoteName = new Map<String,Apttus_Proposal__Proposal__c>();
      Map<String,Apttus_Config2__AccountLocation__c> mapNameToLocation = new Map<String,Apttus_Config2__AccountLocation__c>();
      Map<Id,Apttus_Config2__AccountLocation__c> mapOriginalQuoteToAccountLocation = new Map<Id,Apttus_Config2__AccountLocation__c>();
      Boolean renewed = false;
      //Start BC:4192 - Shikha Dave
      Map<ID, Opportunity> mapPropIDopty = new Map<ID, Opportunity>();
      Set<Id> setOptyID = new Set<Id>();
      Map<String,Apttus_Config2__AccountLocation__c> mapEIDToLocation = new Map<String,Apttus_Config2__AccountLocation__c>();
      Map<Id,Opportunity> mapRenewLegacyOpp = new Map<Id,Opportunity>();
      //End BC:4192

            for( Apttus_Proposal__Proposal__c proposal : newMap.values())
            {
                //Start BC:4192 - Shikha Dave
                
                if ( proposal.Apttus_QPConfig__IsSystemGenerated__c
                     && proposal.Quote_Origin__c == CPQ_ProductConstants.QUOTE_ORIGIN_ORDER 
                     && proposal.Apttus_Proposal__Opportunity__c != null ) {
                    setOptyID.add(proposal.Apttus_Proposal__Opportunity__c);
                }
                //End BC:4192
                else if(proposal.Apttus_QPConfig__IsSystemGenerated__c && proposal.Apttus_Proposal__Opportunity__c!=null && oldMap.get(proposal.Id).Apttus_Proposal__Opportunity__c == null)
                {
                    //proposal.Quote_Type__c = CPQ_constants.Renewal;
                    setRenewalOpportunity.add(proposal.Apttus_Proposal__Opportunity__c);
                    startIndex = proposal.Apttus_Proposal__Proposal_Name__c.indexOf('Q-');
                    originalProposalName = proposal.Apttus_Proposal__Proposal_Name__c.mid(startIndex,10);
                    mapProosalToOriginal.put(proposal.Id,proposal);
                }
                
            }

            //Start BC:4192 - Shikha Dave
            System.debug('setOptyID: '+setOptyID);
            if(!setOptyID.isEmpty() && setOptyID != null){
                try {
                    
                    List<Opportunity> listOpty = [select Id, OwnerId, Distributor__c from Opportunity where Id IN : setOptyID];
                    
                    Map<Id,Apttus_Proposal__Proposal__c> opportunityProposalMap  = New Map<Id,Apttus_Proposal__Proposal__c>();
                    Set<Id> accountLocationIdSet = New Set<Id>();
                    if(listOpty != null){
                        for(Apttus_Proposal__Proposal__c proposalSO : newMap.values()){
                            for(Opportunity opportunitySO: listOpty){
                                if(proposalSO.Apttus_Proposal__Opportunity__c == opportunitySO.Id){
                                    mapPropIDopty.put(proposalSO.Id, opportunitySO);
                                    opportunityProposalMap.put(opportunitySO.Id,proposalSO);
                                    accountLocationIdSet.add(proposalSo.Apttus_QPConfig__LocationId__c);
                                }
                            }
                        }
                        for(Apttus_Proposal__Proposal__c proposal : newMap.values()){
                            proposal.OwnerId = mapPropIDopty.get(proposal.Id).OwnerId;
                            proposal.DIstributor_Account__c = mapPropIDopty.get(proposal.Id).Distributor__c;
                        }

                        List<Apttus_Config2__AccountLocation__c> legacyLocation = 
                            [ Select id,Name,Quote_Id__c, Total_ARR__c,Total_Net_ARR__c, End_Date__c,
                                     Payment_Method_x__c, Core_Seat_Quantity__c,
                                     Payment_Frequency__c, Account_Type_Sold_renewal__c,
                                     CurrencyIsoCode, Box_Seat_ARR__c, Renewal_Quote__c,
                                     Renewal_Opportunity__c, Quote_Id__r.Name,Contract_Term__c,
                                     Is_Auto_renew_removed__c, Box_Enterprise_Id__c 
                              from Apttus_Config2__AccountLocation__c 
                              where id in :accountLocationIdSet ];
                              
                        
                        for(Apttus_Config2__AccountLocation__c oLocation : legacyLocation)
                        {
                           mapEIDToLocation.put(oLocation.Box_Enterprise_Id__c, oLocation);
                        }
                        System.debug('mapEIDToLocation: '+mapEIDToLocation);

                        for(Apttus_Proposal__Proposal__c proposal : newMap.values()){
                            
                            Opportunity renewalOpp = mapPropIDopty.get(proposal.Id);
                            proposal.OwnerId                = renewalOpp.OwnerId;
                            proposal.DIstributor_Account__c = renewalOpp.Distributor__c;

                            for(Apttus_Config2__AccountLocation__c location : mapEIDToLocation.values()){
                                if(location.Box_Enterprise_Id__c == proposal.Box_Enterprise_ID__c){
                                    location.Renewal_Quote__c       = proposal.Id;
                                    location.Renewal_Opportunity__c = renewalOpp.Id;
                                    break;
                                }
                            }
                        }
                        update mapEIDToLocation.values();
                    }

                    String soqlQuery = 'Select Id,Name,AccountId,Pre_Renewal_Renewal_Amount__c,CloseDate,  Pre_Renewal_Payment_Method__c, Pre_Renewal_Contract_Term__c, Box_Enterprise_ID__c,Auto_renew_removed__c,' +
                                        'Pre_Renewal_Payment_Frequency__c,CurrencyIsoCode,Renewal_Date_Renewals__c,Pre_Renewal_Seats_Sold__c,Pre_Renewal_Account_Type_Sold__c,Forecasted_Renewal_Amount__c,Renewal_Amount__c from Opportunity where Id in :setOptyID';

                    List<Opportunity> listRenewLegacyOpp = Database.query(soqlQuery);
                    System.debug('listRenewLegacyOpp: '+listRenewLegacyOpp);
                    
                    if ( listRenewLegacyOpp.size()>0 ) {
                        for ( Opportunity opp : listRenewLegacyOpp ) {
                            mapRenewLegacyOpp.put(opp.Id,opp);
                        }

                        System.debug('mapRenewLegacyOpp: '+mapRenewLegacyOpp);

                        for ( Opportunity oOpp : mapRenewLegacyOpp.values() ) {
                            
                            System.debug('mapEIDToLocation EID: '+mapEIDToLocation.get(oOpp.Box_Enterprise_ID__c));
                            
                            String opportunityEID;

                            Apttus_Proposal__Proposal__c proposal = opportunityProposalMap.containsKey( oOpp.Id )
                                                                        ? opportunityProposalMap.get( oOpp.Id )
                                                                            : null;
                            
                            if ( proposal != null ) {
                                opportunityEID = proposal.Box_Enterprise_ID__c;
                            }

                            Apttus_Config2__AccountLocation__c location = mapEIDToLocation.containsKey( opportunityEID )
                                                                            ? mapEIDToLocation.get( opportunityEID )
                                                                                : null;

                                
                            if ( opportunityEID !=null 
                                 && location != null
                                 && proposal.Quote_Origin__c == CPQ_ProductConstants.QUOTE_ORIGIN_ORDER  ) {

                                System.debug('inside opty fields');
                                oOpp.RecordTypeId = CPQ_constants.renewalRecordType;
                                // ESYS-11630 pre renewal amounts should be based off NET amounts
                                oOpp.Pre_Renewal_Renewal_Amount__c    = location.Total_Net_ARR__c;
                                oOpp.Forecasted_Renewal_Amount__c     = location.Total_Net_ARR__c;
                                oOpp.Renewal_Amount__c                = location.Total_Net_ARR__c;
                                oOpp.Pre_Renewal_Payment_Method__c    = location.Payment_Method_x__c;
                                oOpp.Pre_Renewal_Payment_Frequency__c = location.Payment_Frequency__c;
                                oOpp.Pre_Renewal_Contract_Term__c     = location.Contract_Term__c;
                                oOpp.Pre_Renewal_Account_Type_Sold__c = location.Account_Type_Sold_renewal__c;
                                oOpp.CurrencyIsoCode                  = location.CurrencyIsoCode;
                                oOpp.Pre_Renewal_Seats_Sold__c        = location.Core_Seat_Quantity__c;
                                oOpp.Renewal_Date_Renewals__c         = location.End_Date__c.addDays(1);
                                oOpp.Auto_renew_removed__c            = location.Is_Auto_renew_removed__c;
                                oOpp.CloseDate                        = oOpp.Renewal_Date_Renewals__c;
                            }
                        }
                        update mapRenewLegacyOpp.values();
                    }

                    isLegacyOppty = false;

                } catch( Exception ex ) {
                    SystemMessage.log( 'CPQ_ProposalTriggerHelper method setOpportunityFieldsRenewal failed', ex );                    
                    System.debug('ex.getMessage() '+ ex.getMessage() +' ex.getLineNumber() demo ' + ex.getLineNumber());
                }
            }
            //End BC:4192
            System.debug('setRenewalOpportunity: '+setRenewalOpportunity);
            if(setRenewalOpportunity.size()>0)
            {
                try {
                    List<Schema.FieldSetMember> OppField = SobjectType.Opportunity.FieldSets.getMap().get('Renewal_Opportunity').getFields();
                    for(Schema.FieldSetMember renewalFields : OppField){
                        if(queryOpp<>null){
                            queryOpp += ',';
                            queryOpp += renewalFields.getFieldPath();
                        }
                        else
                            queryOpp = renewalFields.getFieldPath();
                    }
                    String soqlQuery = 'Select Id,Name,AccountId,Pre_Renewal_Renewal_Amount__c,CloseDate,  Pre_Renewal_Payment_Method__c,Auto_renew_removed__c,' +
                                        'Pre_Renewal_Payment_Frequency__c,CurrencyIsoCode,Renewal_Date_Renewals__c,Pre_Renewal_Seats_Sold__c,Pre_Renewal_Account_Type_Sold__c,Forecasted_Renewal_Amount__c,Renewal_Amount__c,' + queryOpp + ' from Opportunity where Id in :setRenewalOpportunity';
                    System.debug(' soqlQuery demo ' + soqlQuery);

                    List<opportunity> renewOpp = Database.query(soqlQuery);
                    for(opportunity opp : renewOpp){
                           startIndex = opp.Name.indexOf('Q-');
                          originalName.add(opp.Name.mid(startIndex,10));
                          renewOppMap.put(opp.Id,opp);
                    }

                    List<Apttus_Proposal__Proposal__c> originalQuote = [Select id,Name,Apttus_Proposal__Opportunity__c,Apttus_Proposal__Proposal_Name__c,
                                                                        Contract_Term__c,PR_Provision_Modified__c,BSA_Extended_To_Affiliates__c,Box_Seat_Arr__c from Apttus_Proposal__Proposal__c where Name in :originalName];
                    for(Apttus_Proposal__Proposal__c proposal :  originalQuote){
                      originalOpportunityRenew.add(proposal.Apttus_Proposal__Opportunity__c);
                      originalOpportunityRenewMap.put(proposal.Name, proposal.Apttus_Proposal__Opportunity__c);
                      renewQuoteName.put(proposal.Name,proposal);
                    }

                    System.debug(' in setDefaulFieldsRenewal  mapProposalToOriginalProposal originalLocation ' + originalProposalName);
                    for(Schema.FieldSetMember renewalFields : OppField){
                        if(queryOriginalOpp<>null)
                        {
                        queryOriginalOpp += ',';
                        queryOriginalOpp += renewalFields.getFieldPath();
                        }
                        else
                            queryOriginalOpp = renewalFields.getFieldPath();
                    }

                    soqlQuery = 'Select Id,Name,AccountId,Pre_Renewal_Renewal_Amount__c,  Pre_Renewal_Payment_Method__c,' +
                                'Pre_Renewal_Payment_Frequency__c,CurrencyIsoCode,Renewal_Date_Renewals__c,Pre_Renewal_Seats_Sold__c,Pre_Renewal_Account_Type_Sold__c,' + queryOriginalOpp + ' from Opportunity where Id in :originalOpportunityRenew';
                    //System.debug(' soqlQuery demo ' + soqlQuery);

                    List<Opportunity> originalOpp = Database.query(soqlQuery);
                    for(Opportunity oOpp : originalOpp){
                      originalOppMap.put(oOpp.Id, oOpp);
                      setAccountLocationIds.put(oOpp.AccountId,oOpp.Box_Enterprise_ID__c);
                    }

                    System.debug(' in setDefaulFieldsRenewal  mapProposalToOriginalProposal originalOpp ' + originalOpp);
                    List<Apttus_Config2__AccountLocation__c> originalLocation = [Select id,Name,Quote_Id__c,Total_ARR__c,Total_Net_ARR__c, End_Date__c,Payment_Method_x__c,Is_Auto_renew_removed__c,Core_Seat_Quantity__c,
                                                                                Payment_Frequency__c,Account_Type_Sold_renewal__c,CurrencyIsoCode,Box_Seat_ARR__c,Renewal_Quote__c,Renewal_Opportunity__c,
                                                                                Quote_Id__r.Name,Contract_Term__c from Apttus_Config2__AccountLocation__c where 
                                                                                Name in :setAccountLocationIds.Values() and  Apttus_Config2__AccountId__c  in :setAccountLocationIds.keyset()];
                    //System.debug(' in setDefaulFieldsRenewal  originalLocation ' + originalLocation);
                    for(Apttus_Config2__AccountLocation__c oLocation : originalLocation){
                       mapNameToLocation.put(oLocation.Name, oLocation);
                       mapOriginalQuoteToAccountLocation.put(oLocation.Id,oLocation);
                    }
                            
                    for(Schema.FieldSetMember renewalFields : OppField){
                        if(OppField<>null){                             
                            //System.debug(' in setDefaulFieldsRenewal  mapProposalToOriginalProposal demo 3 ' + renewalFields.getFieldPath());
                
                            //renewOpp.put(renewalFields.getFieldPath(),originalOpp.get(renewalFields.getFieldPath()));
                            System.debug(' in setDefaulFieldsRenewal  mapProposalToOriginalProposal demo 4 ');

                            for(Opportunity oOpp : renewOppMap.values()){
                                if(originalOppMap.get(originalOpportunityRenewMap.get(oOpp.Name.mid(startIndex,10))).get(renewalFields.getFieldPath())<>null)
                                {
                                    //System.debug(' test demo ' + originalOppMap.get(originalOpportunityRenewMap.get(oOpp.Name.mid(startIndex,10))).get(renewalFields.getFieldPath()));
                                    oOpp.put(renewalFields.getFieldPath(),originalOppMap.get(originalOpportunityRenewMap.get(oOpp.Name.mid(startIndex,10))).get(renewalFields.getFieldPath()));
                                }
                            }
                        }
                    }

                    for(Opportunity oOpp : renewOppMap.values())
                    {
                        //System.debug('renewQuoteName.get(originalProposalName) ' +renewQuoteName.get(originalProposalName));
    
                        oOpp.Opportunity_Type__c = CPQ_constants.Renewal;
                        oOpp.StageName = CPQ_constants.OppStage;
                        oOpp.RecordTypeId = CPQ_constants.renewalRecordType;
                       // ESYS-11630 Pre renewal amounts should be based off NET
                        oOpp.Pre_Renewal_Renewal_Amount__c = mapNameToLocation.get(oOpp.Box_Enterprise_ID__c).Total_Net_ARR__c;
                        oOpp.Forecasted_Renewal_Amount__c  = mapNameToLocation.get(oOpp.Box_Enterprise_ID__c).Total_Net_ARR__c;
                        oOpp.Renewal_Amount__c  = mapNameToLocation.get(oOpp.Box_Enterprise_ID__c).Total_Net_ARR__c;
                        oOpp.Pre_Renewal_Payment_Method__c = mapNameToLocation.get(oOpp.Box_Enterprise_ID__c).Payment_Method_x__c;
                        oOpp.Pre_Renewal_Payment_Frequency__c = mapNameToLocation.get(oOpp.Box_Enterprise_ID__c).Payment_Frequency__c;
                        oOpp.Pre_Renewal_Contract_Term__c = mapNameToLocation.get(oOpp.Box_Enterprise_ID__c).Contract_Term__c;
                        oOpp.Pre_Renewal_Account_Type_Sold__c = mapNameToLocation.get(oOpp.Box_Enterprise_ID__c).Account_Type_Sold_renewal__c;
                        oOpp.CurrencyIsoCode = mapNameToLocation.get(oOpp.Box_Enterprise_ID__c).CurrencyIsoCode;
                        oOpp.Auto_renew_removed__c = mapNameToLocation.get(oOpp.Box_Enterprise_ID__c).Is_Auto_renew_removed__c;
                        //oOpp.Pre_Renewal_Contract_Term__c = renewQuoteName.get(originalProposalName).Contract_Term__c;
                        oOpp.PR_Provision_Modified__c = renewQuoteName.get(originalProposalName).PR_Provision_Modified__c;
                        oOpp.BSA_Extended_To_Affiliates__c = renewQuoteName.get(originalProposalName).BSA_Extended_To_Affiliates__c;
                        //oOpp.Pre_Renewal_Seats_Sold__c = renewQuoteName.get(originalProposalName).Box_Seat_ARR__c;
                        oOpp.Pre_Renewal_Seats_Sold__c = mapNameToLocation.get(oOpp.Box_Enterprise_ID__c).Core_Seat_Quantity__c;
                        if(mapNameToLocation.get(oOpp.Box_Enterprise_ID__c).End_Date__c<>null)
                        {
                            oOpp.Renewal_Date_Renewals__c = mapNameToLocation.get(oOpp.Box_Enterprise_ID__c).End_Date__c + 1;
                            oOpp.CloseDate = oOpp.Renewal_Date_Renewals__c; //BC-3948
                        }
                        System.debug('oOpp.Pre_Renewal_Account_Type_Sold__c ' +oOpp.Pre_Renewal_Account_Type_Sold__c);
                        oOpp.Name = originalOppMap.get(originalOpportunityRenewMap.get(oOpp.Name.mid(startIndex,10))).Name;
                    }
                    //System.debug(' update opp demo ' + renewOppMap.values());
                    update renewOppMap.values();
                    for( Apttus_Proposal__Proposal__c proposal : newMap.values())
                    {
                        if(mapOriginalQuoteToAccountLocation.get(mapProosalToOriginal.get(proposal.Id).Apttus_QPConfig__LocationId__c)<>null)
                        { 
                            mapOriginalQuoteToAccountLocation.get(mapProosalToOriginal.get(proposal.Id).Apttus_QPConfig__LocationId__c).Renewal_Quote__c = proposal.Id;
                            mapOriginalQuoteToAccountLocation.get(mapProosalToOriginal.get(proposal.Id).Apttus_QPConfig__LocationId__c).Renewal_Opportunity__c = proposal.Apttus_Proposal__Opportunity__c;
                            proposal.Pre_Renewal_Account_Type_Sold__c = mapOriginalQuoteToAccountLocation.get(mapProosalToOriginal.get(proposal.Id).Apttus_QPConfig__LocationId__c).Account_Type_Sold_renewal__c;
                        }
                        if(renewOppMap.get(proposal.Apttus_Proposal__Opportunity__c).Box_Partner_Account__r.Channel_Partner__c==null)
                            proposal.Channel_Partner__c = null;
                            proposal.Apttus_Proposal__Proposal_Name__c = renewQuoteName.get(originalProposalName).Apttus_Proposal__Proposal_Name__c;
                  
                    }
                    //System.debug('mapOriginalQuoteToAccountLocation.values ' + mapOriginalQuoteToAccountLocation.values());
                    update mapOriginalQuoteToAccountLocation.values();

                }
                catch(Exception ex)  {
                    SystemMessage.log( 'CPQ_ProposalTriggerHelper method setOpportunityFieldsRenewal failed', ex );
                    System.debug('ex.getMessage() '+ ex.getMessage() +' ex.getLineNumber() demo ' + ex.getLineNumber());
                } 
            }
    }
     
    
    // Added by Yash Modi for BC-989
    public static void setSKUMappings (List<Apttus_Proposal__Proposal__c> newProposals,Map<Id,Apttus_Proposal__Proposal__c> oldMap) {

        Set<Id> proposalIds = new Set<Id> ();
        for (Apttus_Proposal__Proposal__c proposal : newProposals) {
            Apttus_Proposal__Proposal__c oldProposal = oldMap.get(proposal.Id);
            if (oldProposal != null && oldProposal.Payment_Frequency__c != proposal.Payment_Frequency__c) {
                proposalIds.add (proposal.Id);
            }
        }
        if (proposalIds.size() > 0) {
            List<Apttus_Proposal__Proposal_Line_Item__c> proposalLineItems = [SELECT Apttus_QPConfig__PriceListItemId__c, Apttus_Proposal__Proposal__c, Incremental_Quantity__c, Template_Product_Name__c
                                                                              FROM Apttus_Proposal__Proposal_Line_Item__c
                                                                              WHERE Apttus_Proposal__Proposal__r.Id IN :proposalIds];
            Map<Id, Apttus_Proposal__Proposal_Line_Item__c> mapProposalLine = new  Map<Id, Apttus_Proposal__Proposal_Line_Item__c> (proposalLineItems);
            //CPQ_ProposalLineItemTriggerHelper.getTranslatedSKU (mapProposalLine, proposalLineItems);
            //update mapProposalLine.values();
        }
    }
  
    // Added by Yash Modi for BC-3970
    //public static void setAmendedBundleLineStatus (Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap) {
    //    set<Id> setFinalizedProposalIds = new set<Id>();
    //    for(Apttus_Proposal__Proposal__c proposal : newMap.values()) {
    //        if(((oldMap.get(proposal.Id)).Apttus_QPConfig__ConfigurationFinalizedDate__c == null
    //            && proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != null)
    //           || 
    //           (oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != null
    //            && oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c) ) {
                    
    //                    setFinalizedProposalIds.add(proposal.Id);
                    
    //        }
    //    }            
    //    if(setFinalizedProposalIds.size() > 0) {
    //        List<Apttus_Proposal__Proposal_Line_Item__c> proposalLineItems = [SELECT Apttus_QPConfig__LineStatus__c, Apttus_QPConfig__LineNumber__c, Apttus_QPConfig__LineType__c, Apttus_Proposal__Proposal__c 
    //                                                                          FROM Apttus_Proposal__Proposal_Line_Item__c
    //                                                                          WHERE Apttus_Proposal__Proposal__r.Id IN :setFinalizedProposalIds];
    //        Map<Id, List<Apttus_Proposal__Proposal_Line_Item__c>> proposalToPLIMap = new Map<Id, List<Apttus_Proposal__Proposal_Line_Item__c>> ();
    //        for (Apttus_Proposal__Proposal_Line_Item__c proposalLineItem : proposalLineItems) {
    //            List<Apttus_Proposal__Proposal_Line_Item__c> pliList;
    //            if (!proposalToPLIMap.containsKey(proposalLineItem.Apttus_Proposal__Proposal__c)) {
    //              pliList = new List<Apttus_Proposal__Proposal_Line_Item__c> ();
    //              proposalToPLIMap.put(proposalLineItem.Apttus_Proposal__Proposal__c, pliList);
    //            }
    //            pliList = proposalToPLIMap.get(proposalLineItem.Apttus_Proposal__Proposal__c);
    //            pliList.add (proposalLineItem);
    //            proposalToPLIMap.put(proposalLineItem.Apttus_Proposal__Proposal__c, pliList);
    //        }

    //        List<Apttus_Proposal__Proposal_Line_Item__c> listToBeUpdated = new List<Apttus_Proposal__Proposal_Line_Item__c> ();
    //        for (Id proposalId : proposalToPLIMap.keySet()) {
    //            Map<Decimal, Boolean> proposalLineItemLineNumberMap = new Map<Decimal, Boolean> ();
    //            for (Apttus_Proposal__Proposal_Line_Item__c proposalLineItem : proposalToPLIMap.get(proposalId)) {
    //                if (!proposalLineItemLineNumberMap.containsKey(proposalLineItem.Apttus_QPConfig__LineNumber__c)) {
    //                    proposalLineItemLineNumberMap.put(proposalLineItem.Apttus_QPConfig__LineNumber__c, FALSE);
    //                }
    //                proposalLineItemLineNumberMap.put(proposalLineItem.Apttus_QPConfig__LineNumber__c, proposalLineItemLineNumberMap.get(proposalLineItem.Apttus_QPConfig__LineNumber__c) || 
    //                    proposalLineItem.Apttus_QPConfig__LineStatus__c == CPQ_Constants.NEWVAR || proposalLineItem.Apttus_QPConfig__LineStatus__c == CPQ_Constants.AMENDED ||
    //                    proposalLineItem.Apttus_QPConfig__LineStatus__c == CPQ_Constants.CANCELLED);
    //            }
    //            for (Apttus_Proposal__Proposal_Line_Item__c proposalLineItem : proposalToPLIMap.get(proposalId)) {
    //                if (proposalLineItem.Apttus_QPConfig__LineType__c == CPQ_Constants.PRODUCT_SERVICE && proposalLineItem.Apttus_QPConfig__LineStatus__c == CPQ_Constants.EXISTING 
    //                && proposalLineItemLineNumberMap.get(proposalLineItem.Apttus_QPConfig__LineNumber__c)) {
    //                    proposalLineItem.Apttus_QPConfig__LineStatus__c = CPQ_Constants.AMENDED;
    //                    listToBeUpdated.add (proposalLineItem);
    //                }
    //            }
    //        }
    //        update listToBeUpdated;
    //    }
    //}

  //Added by Mitul as part of BC-1281
  /*
  Description : This method handles attribute checks for any differences
  Created by : Mitul Parmar
  Created Date : 05-Jun-2018*/
  private static boolean checkDifferenceForValue(Apttus_Config2__AssetAttributeValue__c assetAttributeValue, Apttus_QPConfig__ProposalProductAttributeValue__c proposalAttributeValue){

    List<Schema.FieldSetMember> attributeList = SObjectType.Apttus_QPConfig__ProposalProductAttributeValue__c.FieldSets.Change_Custom_Attribute.getFields();
    boolean returnFlag = FALSE;
    for(Integer attr=0; attr<attributeList.size(); attr++){
      
      system.debug('Field to check :-- '+attributeList[attr].getFieldPath());
      system.debug(attributeList[attr].getFieldPath() +' Proposal : '+proposalAttributeValue.get(attributeList[attr].getFieldPath())+ ' Asset : '+assetAttributeValue.get(attributeList[attr].getFieldPath()) );
      if(assetAttributeValue.get(attributeList[attr].getFieldPath())  != proposalAttributeValue.get(attributeList[attr].getFieldPath())){
          returnFlag = TRUE;
          system.debug('Field mismatch :-- '+attributeList[attr].getFieldPath());
          break;
      }
    }
    return returnFlag;
  }

    public static void setCustomSOWLinkExtension(Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap){
        set<Id> setFinalizedProposalIds = new set<Id>();
        set<Id> OpportunityIds = new set<Id>();
        for(Apttus_Proposal__Proposal__c proposal : newMap.values()) {
            if(((oldMap.get(proposal.Id)).Apttus_QPConfig__ConfigurationFinalizedDate__c == null && proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != null) || 
               (oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != null && oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c) ) {
                setFinalizedProposalIds.add(proposal.Id);
                OpportunityIds.add(proposal.Apttus_Proposal__Opportunity__c); 
                OpportunityIds.add(proposal.Apttus_Proposal__Opportunity__c);                 
            }
        }

        if(setFinalizedProposalIds.size() > 0) {
            try{

                for(Id ProposalID:setFinalizedProposalIds){
                    newMap.get(ProposalID).Box_Consulting_Start_Link__c = null;
                    newMap.get(ProposalID).Box_consulting_SmartStartPlus_link__c = null;
                    newMap.get(ProposalID).Box_consulting_POC_link__c = null;
                    newMap.get(ProposalID).Box_consulting_Box_Consulting_Hourlink__c = null;
                    newMap.get(ProposalID).Box_consulting_Box_Shuttle_Basic_link__c = null;
                    newMap.get(ProposalID).Box_consulting_Box_Building_Blockslink__c = null;
                    newMap.get(ProposalID).Box_consulting_Box_Shuttle_Advancelink__c = null;
                    newMap.get(ProposalID).Box_consulting_Box_Governance_Setulink__c = null;
                    newMap.get(ProposalID).Box_consulting_optimized_link__c = null;
                    newMap.get(ProposalID).Box_consulting_Box_KeySafe_Setup_link__c = null;
                }

                List<Box_Consulting__c> lisBox=[Select id, Opportunity__c, SOW_Link__c, ConsultingSKU__c, BC_Stamped_Status__c from Box_Consulting__c 
                                      where Opportunity__c in :OpportunityIds and BC_Stamped_Status__c=:CPQ_Constants.COMPLETE];

                Map<Id, Set<Box_Consulting__c> > OpportunityToConsultingMap = new Map<Id, Set<Box_Consulting__c> >();

                for(Box_Consulting__c box:lisBox){
                    if(OpportunityToConsultingMap.get(box.Opportunity__c)!=null){
                        OpportunityToConsultingMap.get(box.Opportunity__c).add(box);
                    }
                    else{
                        OpportunityToConsultingMap.put(box.Opportunity__c, new Set<Box_Consulting__c> {box});
                    }
                }

                List<Apttus_Proposal__Proposal_Line_Item__c> ProposalLIList = [Select  Id,Apttus_Proposal__Proposal__c, Apttus_Proposal__Proposal__r.Apttus_Proposal__Opportunity__c , Apttus_Proposal__Product__r.ProductCode , 
                                                        Apttus_Proposal__Product__r.Consulting_SKU_Name__c  from Apttus_Proposal__Proposal_Line_Item__c 
                                                      where Product_Option_Code__c in : CPQ_Constants.SOWELIGIBLEPRODUCTCODESExtension and Apttus_Proposal__Proposal__c in :setFinalizedProposalIds ]; 

                for(Apttus_Proposal__Proposal_Line_Item__c PLI : ProposalLIList){
                    String OpportunityId = String.valueOf(PLI.Apttus_Proposal__Proposal__r.Apttus_Proposal__Opportunity__c);
                    Id ProposalID = PLI.Apttus_Proposal__Proposal__c;

                    //if(newMap.get(ProposalID).Apttus_Proposal__Primary__c==true){
                    {
                        if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.QUICKSTART_CODE)
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Box_Consulting_Start_Link__c = CPQ_constants.QuickStartBox_Consulting_Start_Link;
                        else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.SMARTSTART_CODE)
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Box_Consulting_Start_Link__c = CPQ_constants.SmartStartBox_Consulting_Start_Link;
                        else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.OPTIMIZEANALYSIS_CODE)
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Box_consulting_optimized_link__c = CPQ_constants.AnalysisBox_consulting_optimized_link;
                        else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.OPTIMIZESTANDARD_CODE)
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Box_consulting_optimized_link__c = CPQ_constants.StandardBox_consulting_optimized_link;
                        else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.SMARTSTARTPLUS_CODE)
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Box_consulting_SmartStartPlus_link__c = CPQ_constants.Box_consulting_SmartStartPlus_link;
                        else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.BUILDINGBLOCKS_CODE)
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Box_consulting_Box_Building_Blockslink__c = CPQ_constants.Box_consulting_Box_Building_Blockslink;
                        else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.KEYSAFEKMSSETUP_CODE)
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Box_consulting_Box_KeySafe_Setup_link__c = CPQ_constants.BOX_KEYSAFE_AWS_CLOUDHSM_SETUP_SOW_LINK;
                        else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.POC_CODE)
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Box_consulting_POC_link__c = CPQ_constants.Box_consulting_POC_link;
                        else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.CONSULTINGHOURS_CODE){
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Box_consulting_Box_Consulting_Hourlink__c = CPQ_constants.BOX_CONSULTING_BOX_CONSULTING_HOURLINK;
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Box_Consulting_Hourlink_2__c = CPQ_constants.BOX_CONSULTING_BOX_CONSULTING_HOURLINK2;
                        }
                        else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.SHUTTLEBASIC_CODE)
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Box_consulting_Box_Shuttle_Basic_link__c = CPQ_constants.Box_consulting_Box_Shuttle_Basic_link;
                        else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.SHUTTLEADVANCED_CODE)
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Box_consulting_Box_Shuttle_Advancelink__c = CPQ_constants.Box_consulting_Box_Shuttle_Advancelink;
                        else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.GOVERNANCESETUP_CODE)
                            newMap.get(PLI.Apttus_Proposal__Proposal__c).Box_consulting_Box_Governance_Setulink__c = CPQ_constants.Box_consulting_Box_Governance_Setulink;
                    }

                    //if(OpportunityToConsultingMap.get(OpportunityId)!=null && newMap.get(ProposalID).Apttus_Proposal__Primary__c==true){
                    if(OpportunityToConsultingMap.get(OpportunityId)!=null){
                        //System.debug('PLI.Apttus_Proposal__Product__r.Consulting_SKU_Name__c'+PLI.Apttus_Proposal__Product__r.Consulting_SKU_Name__c);
                        for(Box_Consulting__c box:OpportunityToConsultingMap.get(OpportunityId)){
                        //System.debug('ConsultingSKU__c'+box.ConsultingSKU__c);
                            if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.QUICKSTART_CODE || PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.SMARTSTART_CODE){
                                if(box.ConsultingSKU__c==PLI.Apttus_Proposal__Product__r.Consulting_SKU_Name__c){
                                    newMap.get(ProposalID).Box_Consulting_Start_Link__c = box.SOW_Link__c;
                                }
                                else
                                if(box.ConsultingSKU__c==CPQ_Constants.MULTIPLE_CONSULTINGSKU){
                                    newMap.get(ProposalID).Box_Consulting_Start_Link__c = box.SOW_Link__c;
                                    break;
                                }
                            }
                            else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.SMARTSTARTPLUS_CODE){
                                if(box.ConsultingSKU__c==PLI.Apttus_Proposal__Product__r.Consulting_SKU_Name__c){
                                    newMap.get(ProposalID).Box_consulting_SmartStartPlus_link__c = box.SOW_Link__c;
                                }
                                else
                                if(box.ConsultingSKU__c==CPQ_Constants.MULTIPLE_CONSULTINGSKU){
                                    newMap.get(ProposalID).Box_consulting_SmartStartPlus_link__c = box.SOW_Link__c;
                                    break;
                                }                                
                            }
                            else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.POC_CODE){
                                if(box.ConsultingSKU__c==PLI.Apttus_Proposal__Product__r.Consulting_SKU_Name__c){
                                    newMap.get(ProposalID).Box_consulting_POC_link__c = box.SOW_Link__c;
                                }
                                else
                                if(box.ConsultingSKU__c==CPQ_Constants.MULTIPLE_CONSULTINGSKU){
                                    newMap.get(ProposalID).Box_consulting_POC_link__c = box.SOW_Link__c;
                                    break;
                                }
                            }
                            else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.CONSULTINGHOURS_CODE){
                                if(box.ConsultingSKU__c==PLI.Apttus_Proposal__Product__r.Consulting_SKU_Name__c){
                                    newMap.get(ProposalID).Box_consulting_Box_Consulting_Hourlink__c = box.SOW_Link__c;
                                    newMap.get(ProposalID).Box_Consulting_Hourlink_2__c = null;
                                }
                                else
                                if(box.ConsultingSKU__c==CPQ_Constants.MULTIPLE_CONSULTINGSKU){
                                    newMap.get(ProposalID).Box_consulting_Box_Consulting_Hourlink__c = box.SOW_Link__c;
                                    newMap.get(ProposalID).Box_Consulting_Hourlink_2__c = null;
                                    break;
                                }
                            }
                            else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.SHUTTLEBASIC_CODE){
                                if(box.ConsultingSKU__c==PLI.Apttus_Proposal__Product__r.Consulting_SKU_Name__c){
                                    newMap.get(ProposalID).Box_consulting_Box_Shuttle_Basic_link__c = box.SOW_Link__c;
                                }
                                else
                                if(box.ConsultingSKU__c==CPQ_Constants.MULTIPLE_CONSULTINGSKU){
                                    newMap.get(ProposalID).Box_consulting_Box_Shuttle_Basic_link__c = box.SOW_Link__c;
                                    break;
                                }
                            }
                            else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.SHUTTLEADVANCED_CODE){
                                if(box.ConsultingSKU__c==PLI.Apttus_Proposal__Product__r.Consulting_SKU_Name__c){
                                    newMap.get(ProposalID).Box_consulting_Box_Shuttle_Advancelink__c = box.SOW_Link__c;
                                }
                                else
                                if(box.ConsultingSKU__c==CPQ_Constants.MULTIPLE_CONSULTINGSKU){
                                    newMap.get(ProposalID).Box_consulting_Box_Shuttle_Advancelink__c = box.SOW_Link__c;
                                    break;
                                }                              
                            }
                            else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.GOVERNANCESETUP_CODE){
                                if(box.ConsultingSKU__c==PLI.Apttus_Proposal__Product__r.Consulting_SKU_Name__c){
                                    newMap.get(ProposalID).Box_consulting_Box_Governance_Setulink__c = box.SOW_Link__c;
                                }
                                else
                                if(box.ConsultingSKU__c==CPQ_Constants.MULTIPLE_CONSULTINGSKU){
                                    newMap.get(ProposalID).Box_consulting_Box_Governance_Setulink__c = box.SOW_Link__c;
                                    break;
                                }                              
                            }
                            else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.OPTIMIZEANALYSIS_CODE || PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.OPTIMIZESTANDARD_CODE){
                                if(box.ConsultingSKU__c==PLI.Apttus_Proposal__Product__r.Consulting_SKU_Name__c){
                                    newMap.get(ProposalID).Box_consulting_optimized_link__c = box.SOW_Link__c;
                                }
                                else
                                if(box.ConsultingSKU__c==CPQ_Constants.MULTIPLE_CONSULTINGSKU){
                                    newMap.get(ProposalID).Box_consulting_optimized_link__c = box.SOW_Link__c;
                                    break;
                                }                              
                            }
                            else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.BUILDINGBLOCKS_CODE){
                                if(box.ConsultingSKU__c==PLI.Apttus_Proposal__Product__r.Consulting_SKU_Name__c){
                                    newMap.get(ProposalID).Box_consulting_Box_Building_Blockslink__c = box.SOW_Link__c;
                                }
                                else
                                if(box.ConsultingSKU__c==CPQ_Constants.MULTIPLE_CONSULTINGSKU){
                                    newMap.get(ProposalID).Box_consulting_Box_Building_Blockslink__c = box.SOW_Link__c;
                                    break;
                                }
                            }
                            else if(PLI.Apttus_Proposal__Product__r.ProductCode == CPQ_Constants.KEYSAFEKMSSETUP_CODE){
                                if(box.ConsultingSKU__c==PLI.Apttus_Proposal__Product__r.Consulting_SKU_Name__c){
                                    newMap.get(ProposalID).Box_consulting_Box_KeySafe_Setup_link__c = box.SOW_Link__c;
                                }
                                else
                                if(box.ConsultingSKU__c==CPQ_Constants.MULTIPLE_CONSULTINGSKU){
                                    newMap.get(ProposalID).Box_consulting_Box_KeySafe_Setup_link__c = box.SOW_Link__c;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            catch(Exception ex)  {
                SystemMessage.log( 'CPQ_ProposalTriggerHelper method setCustomSOWLinkExtension failed', ex );
                System.debug(ex.getMessage());
                //System.debug(ex.getLineNumber());
                //System.debug(ex.getCause());
            } 
        }
    }

    //Added by Anay Bhande: JIRA BC-802 
    public static void setCustomSOWLink(Map<Id,Apttus_Proposal__Proposal__c> newMap,Map<Id,Apttus_Proposal__Proposal__c> oldMap){
        
        set<Id> setFinalizedProposalIds = new set<Id>();
        set<Id> OpportunityIds = new set<Id>();
        for(Apttus_Proposal__Proposal__c proposal : newMap.values()) {
            if(((oldMap.get(proposal.Id)).Apttus_QPConfig__ConfigurationFinalizedDate__c == null && proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != null) || 
               (oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != null && oldMap.get(proposal.Id).Apttus_QPConfig__ConfigurationFinalizedDate__c != proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c) ) {
                setFinalizedProposalIds.add(proposal.Id);
                OpportunityIds.add(proposal.Apttus_Proposal__Opportunity__c);                  
            }
        }
        if(setFinalizedProposalIds.size() > 0) {
            try{

                  List<Box_Consulting__c> lisBox=[Select id, Opportunity__c, SOW_Link__c, ConsultingSKU__c from Box_Consulting__c 
                                          where Opportunity__c in :OpportunityIds and BC_Stamped_Status__c=:CPQ_Constants.COMPLETE];

                  Map<Id, Set<Box_Consulting__c> > OpportunityToConsultingMap = new Map<Id, Set<Box_Consulting__c> >();

                  for(Box_Consulting__c box:lisBox){
                      if(OpportunityToConsultingMap.get(box.Opportunity__c)!=null){
                          OpportunityToConsultingMap.get(box.Opportunity__c).add(box);
                      }
                      else{
                          OpportunityToConsultingMap.put(box.Opportunity__c, new Set<Box_Consulting__c> {box});
                      }
                  }

                  AggregateResult[] ProposalList = [Select count(Id) countId, Apttus_Proposal__Proposal__c, Apttus_Proposal__Proposal__r.Apttus_Proposal__Opportunity__c opportunity, Apttus_Proposal__Product__r.ProductCode productCode, Apttus_Proposal__Product__r.Consulting_SKU_Name__c consultingname from Apttus_Proposal__Proposal_Line_Item__c 
                                                          where Product_Option_Code__c in : CPQ_Constants.SOWELIGIBLEPRODUCTCODES and Apttus_Proposal__Proposal__c in :setFinalizedProposalIds group by Apttus_Proposal__Proposal__c, Apttus_Proposal__Product__r.ProductCode, Apttus_Proposal__Product__r.Consulting_SKU_Name__c, Apttus_Proposal__Proposal__r.Apttus_Proposal__Opportunity__c]; 
                  
                  Map<Id,Integer> ProposalToCustomCount =new Map<Id, Integer>();
                  Map<Id,Integer> ProposalToPlatformCount =new Map<Id, Integer>();
                  Map<Id,Integer> ProposalToKeysafeCount =new Map<Id, Integer>();
                  Map<Id,Integer> ProposalToSOWCount =new Map<Id, Integer>();

                  for(Id pId:setFinalizedProposalIds){
                      ProposalToCustomCount.put(pId,0);
                      ProposalToPlatformCount.put(pId,0);
                      ProposalToKeysafeCount.put(pId,0);
                      ProposalToSOWCount.put(pId,0);
                  }

                  for (AggregateResult ar : ProposalList)  {
                      String OpportunityId='';
                      if(ar.get('opportunity')!=null){
                          OpportunityId=string.valueOf(ar.get('opportunity'));
                      }
                      String ProposalID=string.valueOf(ar.get('Apttus_Proposal__Proposal__c'));
                      String ProductCode, CustomLink= '', PlatformLink= '', KeySafeLink = '', Consulting ='';
                      Integer count=0;
                      if(ar.get('countId')!=null){
                          count = Integer.valueof(ar.get('countId'));
                      }
                      if(ar.get('consultingname')!=null)
                      Consulting=string.valueOf(ar.get('consultingname'));
                      if(ar.get('productCode')!=null)
                      ProductCode=string.valueOf(ar.get('productCode'));
                      ProposalToSOWCount.put(ProposalID, ProposalToSOWCount.get(ProposalID)+count);
                      if(ProposalID!= null && newMap.get(ProposalID)!=NULL){
                        //for(Box_Consulting__c box:OpportunityToConsultingMap.get(OpportunityId))
                        System.debug(Consulting+' ConsultingSKU__c ');
                          if(ProductCode==CPQ_Constants.PLATFORMCONSULTING_CODE){
                              count+=ProposalToPlatformCount.get(ProposalID);
                              ProposalToPlatformCount.put(ProposalID,count);
                              newMap.get(ProposalID).Platform_Custom_Consulting_SOW_Link__c = null;                
                              //if(OpportunityToConsultingMap.get(OpportunityId)!=null && newMap.get(ProposalID).Apttus_Proposal__Primary__c==true){
                              if(OpportunityToConsultingMap.get(OpportunityId)!=null){
                                  for(Box_Consulting__c box:OpportunityToConsultingMap.get(OpportunityId)){
                                      if(box.ConsultingSKU__c==Consulting){
                                          newMap.get(ProposalID).Platform_Custom_Consulting_SOW_Link__c = box.SOW_Link__c;
                                      }
                                      else
                                      if(box.ConsultingSKU__c==CPQ_Constants.MULTIPLE_CONSULTINGSKU){
                                        System.debug('inside consulting' + Consulting+' ConsultingSKU__c '+box.SOW_Link__c);
                                          newMap.get(ProposalID).Platform_Custom_Consulting_SOW_Link__c = box.SOW_Link__c;
                                          break;
                                      }
                                  }                                
                              }
                          }
                          else if(ProductCode==CPQ_Constants.CUSTOMTRAINING_CODE){
                              count+=ProposalToCustomCount.get(ProposalID);
                              ProposalToCustomCount.put(ProposalID,count);
                              newMap.get(ProposalID).Custom_Consulting_SOW_Link__c = null;
                              //if(OpportunityToConsultingMap.get(OpportunityId)!=null && newMap.get(ProposalID).Apttus_Proposal__Primary__c==true){
                              if(OpportunityToConsultingMap.get(OpportunityId)!=null){
                                  for(Box_Consulting__c box:OpportunityToConsultingMap.get(OpportunityId)){
                                      if(box.ConsultingSKU__c==Consulting){
                                          newMap.get(ProposalID).Custom_Consulting_SOW_Link__c = box.SOW_Link__c;
                                      }
                                      else
                                      if(box.ConsultingSKU__c==CPQ_Constants.MULTIPLE_CONSULTINGSKU){
                                          newMap.get(ProposalID).Custom_Consulting_SOW_Link__c = box.SOW_Link__c;
                                          break;
                                      }
                                  }                                
                              }
                          }
                          else if(ProductCode==CPQ_Constants.KEYSAFESETUP_CODE){
                              count+=ProposalToKeysafeCount.get(ProposalID);
                              ProposalToKeysafeCount.put(ProposalID,count);
                              newMap.get(ProposalID).Box_KeySafe_AWS_CloudHSM_Setup_SOW_link__c = null;
                              //if(OpportunityToConsultingMap.get(OpportunityId)!=null && newMap.get(ProposalID).Apttus_Proposal__Primary__c==true){
                              if(OpportunityToConsultingMap.get(OpportunityId)!=null){
                                  for(Box_Consulting__c box:OpportunityToConsultingMap.get(OpportunityId)){
                                      if(box.ConsultingSKU__c==Consulting){
                                          newMap.get(ProposalID).Box_KeySafe_AWS_CloudHSM_Setup_SOW_link__c = box.SOW_Link__c;
                                      }
                                      else
                                      if(box.ConsultingSKU__c==CPQ_Constants.MULTIPLE_CONSULTINGSKU){
                                          newMap.get(ProposalID).Box_KeySafe_AWS_CloudHSM_Setup_SOW_link__c = box.SOW_Link__c;
                                          break;
                                      }                                      
                                  }
                              }
                          }
                      }
                  }

                  for(Id pId:setFinalizedProposalIds){
                      if(ProposalToCustomCount.get(pId)==0){
                          newMap.get(pId).Custom_Consulting_SOW_Link__c = null;
                      }
                      if(ProposalToPlatformCount.get(pId)==0){
                          newMap.get(pId).Platform_Custom_Consulting_SOW_Link__c = null;                        
                      }
                      if(ProposalToKeysafeCount.get(pId)==0){
                          newMap.get(pId).Box_KeySafe_AWS_CloudHSM_Setup_SOW_link__c = null;                        
                      }
                      newMap.get(pId).Count_of_SOW_eligible_products__c = ProposalToSOWCount.get(pId);
                  }

              }
              catch(Exception ex)  {
                    SystemMessage.log( 'CPQ_ProposalTriggerHelper method setCustomSOWLink failed', ex );
                    System.debug(ex.getMessage());
                    //System.debug(ex.getLineNumber());
                    //System.debug(ex.getCause());
              }    
        }
    }
    public static void copyInfoFromAccountLocation(List<Apttus_Proposal__Proposal__c> newProposal,Map<Id,Apttus_Proposal__Proposal__c> oldMapProposal ) {
    set<string> EidIds = new set<string>();
    map<Id,Apttus_Config2__AccountLocation__c> ac_Map = new map<Id,Apttus_Config2__AccountLocation__c>();
    try{
        for(Apttus_Proposal__Proposal__c app : newProposal) {
        if (!app.Apttus_QPConfig__IsSystemGenerated__c) {
                if(app.Is_Auto_renew_removed__c <> null && app.Apttus_QPConfig__LocationId__c <> null && ((app.Is_Auto_renew_removed__c <> oldMapProposal.get(app.Id).Is_Auto_renew_removed__c) || (app.Apttus_QPConfig__LocationId__c<> oldMapProposal.get(app.Id).Apttus_QPConfig__LocationId__c))) {
                    EidIds.add(app.Box_Enterprise_ID__c);
                }
            }
            }
            if(EidIds.size()>0) {
                for(Apttus_Config2__AccountLocation__c ac : [SELECT id,BillTo_Contact__c,SoldTo_Contact__c,name,Past_Due_Balance__c,Apttus_Config2__AccountId__c,Is_Auto_renew_removed__c FROM Apttus_Config2__AccountLocation__c WHERE name IN : EidIds]) {
                    ac_Map.put(ac.id,ac);
                }
            }
            if(!ac_Map.isEmpty()) {
                for(Apttus_Proposal__Proposal__c app : newProposal) {
                    if(ac_Map.ContainsKey(app.Box_Enterprise_ID__c)){
                        app.Is_Auto_renew_removed__c = ac_Map.get(app.Box_Enterprise_ID__c).Is_Auto_renew_removed__c;
                    }
            }
        
        }
    }
    catch(Exception ex){
        SystemMessage.log( 'CPQ_ProposalTriggerHelper method updateRemoveAutoRenew failed', ex );
        System.debug(ex.getMessage());
        
    }  
} 
 //ESYS-12719 start
    public static void setCheckSubmitForApprovalFlag(Apttus_Proposal__Proposal__c proposal){
        Double totalArrUSD = CPQ_ProposalUtility.getTotalArrUSD( proposal );
        if(proposal != null){
            System.Debug('#### totalArrUSD'+totalArrUSD +' '+proposal.Payment_Method__c);
            if( totalArrUSD < 1000 
            && proposal.Quote_Type__c != CPQ_constants.UPSELL 
            && proposal.Payment_Method__c != CPQ_Constants.CREDIT_CARD 
            && !proposal.Is_Channel__c ){
            
                proposal.Check_Submit_for_Approval__c = true;
                System.debug( '~~~ approval required for less than $1,000 non credit card' );
            }
            
            else if( totalArrUSD > 20000
            && proposal.Payment_Method__c == CPQ_Constants.CREDIT_CARD ){
            
                proposal.Check_Submit_for_Approval__c = true;
            System.debug( '~~~ approval required for greater than $20,000 and is credit card' );
            }
            
            else {
            
                 proposal.Check_Submit_for_Approval__c = false; 
            }
        }
            
    }
    //ESYS-12719 End
}