#coding:utf-8
##Python 2.7.3
'''
Created on Nov 10, 2012

@author: martin
'''
from selenium import webdriver
import string
import re
import time
from selenium.common.exceptions import NoSuchElementException

timeout = 0.03

#Funktsioonid
#############
 
#Funktsioon tagastab ette antud aktsiasümbolile vastava ettevõtte täispika nime
def get_full_company_name(target_company, browser):
    browser.get("http://google.com/finance?q="+ target_company)
    time.sleep(timeout)
    try:
        element = browser.find_element_by_class_name("appbar-snippet-primary")
    except NoSuchElementException:
        try:
            time.sleep(2)
            element = browser.find_element_by_class_name("appbar-snippet-primary")
        except NoSuchElementException:
            browser.find_element_by_link_text(target_company).click()
            time.sleep(2)
            element = browser.find_element_by_class_name("appbar-snippet-primary")
    return element.text

#Funktsioon tagastab listi argumendina määratud ettevõttega seotud ettevõtete nimedega
def get_related_companies(target_company, browser, current_depth,max_depth, result):
    related_companies = []
    symbols = []
    
    try:
        browser.get("http://google.com/finance?q="+ target_company)
        time.sleep(timeout)
        #Küsime terve seotud ettevõtete HTML tabeli
        try:
            element = browser.find_element_by_id("cc-table")
        except NoSuchElementException:
            try:
                time.sleep(2)
                element = browser.find_element_by_id("cc-table")
            except NoSuchElementException:
                browser.find_element_by_link_text(target_company).click()
                time.sleep(2)
                element = browser.find_element_by_id("cc-table")
        lines=string.split(element.text, '\n')
    
        #eemaldame tabeli esimesed 3 rida, mis ei sisalda antud ülesande jaoks vajalikke andmeid
        lines=lines[3:]
    
        for line in lines:
            print line
            #aktsiasümboli ja ettevõtte nime extractimine
            line=(re.split('\d+\.\d+',line)[0])
            #Salvestame need eraldi massividesse
            symbols.append(line.partition(' ')[0])
            print line.partition(' ')[0]
            related_companies.append(line.partition(' ')[2])
            print line.partition(' ')[2]
    
        #'...'-lõpuliste firmanimede puhul küsime Google Finance'st nende täispikad nimed    
        for company in related_companies:
            if "..." in company:
                company = get_full_company_name(symbols[related_companies.index(company)], browser)
            print company
                
            
            #result.append(target_company+';'+company)
            
        target_company=get_full_company_name(target_company, browser)
        #Add to result dictionary
        result[target_company] = related_companies
        
        if current_depth<max_depth:
            for symbol in symbols:
                if related_companies[symbols.index(symbol)] not in result.keys():
                    get_related_companies(symbol, browser, current_depth+1, max_depth, result)
                else:
                    continue      
        else: #current_depth=max_depth        
            return result
    except:
        return result

#############################################
target_company = "MRVL"

browser = webdriver.Firefox()

results={}

#print get_full_company_name("ISSI", browser)
get_related_companies(target_company, browser, 0, 2, results)
#get_full_company_name('FIRM', browser)

'''for symbol in ["MU","ISSI","INTC"]:
            get_related_companies(symbol, browser, 1, 1, results)'''

with open("/home/martin/out.txt", "w") as f:
    for key in results.keys():
        for company in results[key]:
            f.write(key + ';' + company + '\n')
print 'Done'

browser.close()    



