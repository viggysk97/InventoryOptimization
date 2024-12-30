/* Data Loading */
data sales_data;
    infile '/home/u63786055/SalesKaggle3.csv' dsd firstobs=2;
    input
        Order : $10.
        File_Type : $50.
        SKU_number : 8.
        SoldFlag : 8.
        SoldCount : 8.
        Marketing : $10.
        ReleaseNumber : 8.
        New_Release_Flag : 8.
        StrengthFactor : 8.
        PriceReg : 8.
        ReleaseYear : 4.
        ItemCount : 8.
        LowUserPrice : 8.
        LowNetPrice : 8.
run;

/* Data Summary */
PROC MEANS DATA=sales_data N MEAN STD MIN MAX;
    VAR SoldCount ItemCount PriceReg LowUserPrice LowNetPrice;
RUN;

/* Missing values check */
PROC FREQ DATA=sales_data;
    TABLES SoldFlag New_Release_Flag;
RUN;

PROC MEANS DATA=sales_data N NMISS;
    VAR SoldCount ItemCount PriceReg LowUserPrice LowNetPrice;
RUN;

    
/* Visualize sales over time */
PROC SGPLOT DATA=sales_data;
    SERIES X=ReleaseYear Y=SoldCount;
    TITLE "Sales Trends Over Time";
    XAXIS LABEL="Release Year";
    YAXIS LABEL="Count";
RUN;

/* Correlation analysis */
PROC CORR DATA=sales_data;
    VAR SoldCount ItemCount PriceReg LowUserPrice LowNetPrice StrengthFactor;
RUN;

/* Calculate Total Sales for Each Product */
PROC SQL;
    CREATE TABLE product_sales AS
    SELECT SKU_number,
           SUM(SoldCount) AS Total_Sales
    FROM sales_data
    GROUP BY SKU_number;
QUIT;

/* Calculate Grand Total Sales */
PROC SQL;
    SELECT SUM(Total_Sales) INTO :GrandTotalSales FROM product_sales;
QUIT;

/* Calculate Cumulative Sales and Percentages Using Subqueries */
PROC SQL;
    CREATE TABLE cumulative_sales AS
    SELECT a.SKU_number,
           a.Total_Sales,
           (SELECT SUM(b.Total_Sales)
            FROM product_sales b
            WHERE b.Total_Sales >= a.Total_Sales) AS Cumulative_Sales,
           CALCULATED Cumulative_Sales / &GrandTotalSales * 100 AS Cumulative_Percentage,
           CASE
               WHEN CALCULATED Cumulative_Percentage <= 60 THEN 'A'
               WHEN CALCULATED Cumulative_Percentage <= 70 THEN 'B'
               ELSE 'C'
           END AS ABC_Category
    FROM product_sales a
    ORDER BY Total_Sales DESC;
QUIT;

/* View Results */
PROC PRINT DATA=cumulative_sales;
    VAR SKU_number Total_Sales Cumulative_Sales Cumulative_Percentage;
RUN;

/* Summarize ABC Categories */
PROC FREQ DATA=cumulative_sales;
    TABLES ABC_Category / NOCUM;
    TITLE "Summary of ABC Categories";
RUN;

/* Visualize ABC Categories */
PROC SGPLOT DATA=cumulative_sales;
    VBAR ABC_Category / RESPONSE=Total_Sales STAT=SUM;
    TITLE "ABC Categorization - Total Sales Contribution by Category";
    XAXIS LABEL="ABC Category";
    YAXIS LABEL="Total Sales Contribution";
RUN;


/*Time-Series Forecasting*/
PROC ARIMA DATA=sales_data;
    IDENTIFY VAR=SoldCount;
    ESTIMATE;
    FORECAST LEAD=12 INTERVAL=YEAR OUT=forecast_results;
RUN;

/*Inventory Reporting*/
PROC REPORT DATA=sales_data NOWD;
    COLUMN SKU_number SoldCount ItemCount PriceReg;
    DEFINE SKU_number / "SKU Number";
    DEFINE SoldCount / "Units Sold";
    DEFINE ItemCount / "Inventory";
    DEFINE PriceReg / "Regular Price";
RUN;

/*Inventory Turnover*/
DATA inventory_turnover;
    SET sales_data;
    Turnover = SoldCount / ItemCount;
RUN;

PROC MEANS DATA=inventory_turnover MEAN STD;
    VAR Turnover;
RUN;



