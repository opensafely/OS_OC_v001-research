import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import plotly.graph_objects as go
import json
import datetime
from dateutil.relativedelta import relativedelta
import os

# https://github.com/ebmdatalab/datalab-pandas/blob/master/ebmdatalab/charts.py#L20
def add_percentiles(df, period_column=None, column=None, show_outer_percentiles=True):
    """For each period in `period_column`, compute percentiles across that
    range.
    Adds `percentile` column.
    """
    deciles = np.arange(0.1, 1, 0.1)
    bottom_percentiles = np.arange(0.01, 0.1, 0.01)
    top_percentiles = np.arange(0.91, 1, 0.01)
    if show_outer_percentiles:
        quantiles = np.concatenate((deciles, bottom_percentiles, top_percentiles))
    else:
        quantiles = deciles
    df = df.groupby(period_column)[column].quantile(quantiles).reset_index()
    df = df.rename(index=str, columns={"level_1": "percentile"})
    # create integer range of percentiles
    df["percentile"] = df["percentile"].apply(lambda x: int(x * 100))
    return df


def to_datetime_sort(df):
    df['date'] = pd.to_datetime(df['date'])
    df = df.sort_values(by='date')


def redact_small_numbers(df, n, m):
    """
    Takes measures df and converts any row to nana where value of denominator or numerater in measure m equal to 
    or below n
    Returns df of same shape.
    """
    mask_n = df[m.numerator].isin(list(range(0, n+1)))
    mask_d = df[m.denominator].isin(list(range(0, n+1)))
    mask = mask_n | mask_d
    df.loc[mask, :] = np.nan
    return df


def calculate_rate(df, value_col='had_smr', population_col='population', rate_per=1000):
    num_per_thousand = df[value_col]/(df[population_col]/rate_per)
    df['rate'] = num_per_thousand



def plot_measures(df, title, measure_id, column_to_plot, category=False, y_label='Rate per 1000', interactive=True):

    if interactive:

        fig = go.Figure()

        if category:
            for unique_category in df[category].unique():

                df_subset = df[df[category] == unique_category]
                fig.add_trace(go.Scatter(
                    x=df_subset['date'], y=df_subset[column_to_plot], name=unique_category))

        else:
            fig.add_trace(go.Scatter(
                x=df['date'], y=df[column_to_plot]))

        # Set title
        fig.update_layout(
            title_text=title,
            hovermode='x',
            title_x=0.5,


        )

        fig.update_yaxes(title=y_label)
        fig.update_xaxes(title="Date")

        # Add range slider
        fig.update_layout(
            xaxis=go.layout.XAxis(
                rangeselector=dict(
                    buttons=list([
                        dict(count=1,
                            label="1m",
                            step="month",
                            stepmode="backward"),
                        dict(count=6,
                            label="6m",
                            step="month",
                            stepmode="backward"),

                        dict(count=1,
                            label="1y",
                            step="year",
                            stepmode="backward"),
                        dict(step="all")
                    ])
                ),
                rangeslider=dict(
                    visible=True
                ),
                type="date"
            )
        )

        fig.show()

    else:

        if category:
            for unique_category in df[category].unique():

                df_subset = df[df[category] == unique_category]

                plt.plot(df_subset['date'], df_subset[column_to_plot], marker='o')
        else:
            plt.plot(df['date'], df[column_to_plot], marker='o')

        plt.ylabel(y_label)
        plt.xlabel('Date')
        plt.xticks(rotation='vertical')
        plt.title(title)

        if category:
            plt.legend(df[category].unique(), bbox_to_anchor=(
                1.04, 1), loc="upper left")

        else:
            pass

        plt.savefig(f'output/{measure_id}.jpeg', bbox_inches='tight')
        plt.show()
        plt.clf()







def drop_irrelevant_practices(df):
    #drop practices that do not use the code
    mean_value_df = df.groupby("practice")["value"].mean().reset_index()

    practices_to_drop = list(
        mean_value_df['practice'][mean_value_df['value'] == 0])

    #drop
    df = df[~df['practice'].isin(practices_to_drop)]

    return df






def get_child_codes(df, measure):

    event_code_column = f'{measure}_event_code'
    event_column = f'{measure}'

    counts = df.groupby(event_code_column)[event_column].sum()
    code_dict = dict(counts)

    return code_dict


def create_child_table(df, code_df, code_column, term_column, measure, nrows=5):
    #pass in df from data_dict
    #code df contains first digits and descriptions

    #get codes counts
    code_dict = get_child_codes(df, measure)

    #make df of events for each subcode
    df = pd.DataFrame.from_dict(
        code_dict, orient="index", columns=["Events"])
    df[code_column] = df.index

    #convert events to events/thousand
    df['Events (thousands)'] = df['Events'].apply(lambda x: x/1000)
    df.drop(columns=['Events'])

    #order by events
    df.sort_values(by='Events (thousands)', inplace=True)
    df = df.iloc[:, [1, 0, 2]]

    #get description for each code

    def get_description(row):
        code = row[code_column]

        try:
            description = code_df[code_df[code_column]
                              == code][term_column].values[0]
        except:
            description = "__"
        #description="__"

        return description

    df['Description'] = df.apply(
        lambda row: get_description(row), axis=1)

    #return top n rows
    return df.iloc[:nrows, :]


def get_patients_counts(df, event_column, end_date):
    f = open("output/patient_count.json")
    num_patients = json.load(f)['num_patients']
    dates = list(num_patients.keys())

    dates = sorted(dates)

    def get_counts_from_dates_list(dates):
        patients = np.concatenate([num_patients[date] for date in dates])
        patients_total = len(np.unique(patients))
        return patients_total

    patients_total = get_counts_from_dates_list(dates)

    end_date = datetime.datetime.strptime(end_date, '%Y-%m-%d')
    year_before = end_date - relativedelta(years=1)
    dates_year = [i for i in dates if datetime.datetime.strptime(
        i, '%Y-%m-%d') > year_before]
    patients_year = get_counts_from_dates_list(dates_year)

    months_3_before = end_date - relativedelta(months=3)
    dates_months_3 = [i for i in dates if datetime.datetime.strptime(
        i, '%Y-%m-%d') > months_3_before]
    patients_months_3 = get_counts_from_dates_list(dates_months_3)

    numbers_dict = {"total": patients_total,
                    "year": patients_year, "months_3": patients_months_3}
    return numbers_dict
    

def get_number_practices(df, end_date):
    
    num_practices_total = len(np.unique(df['practice']))

    end_date = datetime.datetime.strptime(
        end_date, '%Y-%m-%d')


    year_before = end_date - relativedelta(years=1)
    months_3_before = end_date - relativedelta(months=3)

    df_subset_year = df[df['date'] > year_before]
    num_practices_year = len(np.unique(df_subset_year['practice']))

    df_subset_months_3 = df[df['date'] > months_3_before]
    num_practices_months_3 = len(np.unique(df_subset_months_3['practice']))

    numbers_dict = {"total": num_practices_total, "year": num_practices_year, "3_months": num_practices_months_3}
    return numbers_dict


def get_number_events(df, events_column, end_date):

    end_date = datetime.datetime.strptime(
        end_date, '%Y-%m-%d')

    year_before = end_date - relativedelta(years=1)
    months_3_before = end_date - relativedelta(months=3)

    num_events_total = df[events_column].sum()

    df_subset_year = df[df['date'] > year_before]
    num_events_year = df_subset_year[events_column].sum()

    df_subset_months_3 = df[df['date'] > months_3_before]
    num_events_months_3 = df_subset_months_3[events_column].sum()

    numbers_dict = {"total": num_events_total,
                    "year": num_events_year, "months_3": num_events_months_3}
    return numbers_dict


def calculate_statistics_practices(df, practice_df, end_date):

    
    num_practices = len(np.unique(practice_df['practice']))


    # calculate number of unique practices and caluclate as % of total
    practices_included_total = get_number_practices(df, end_date)['total']
    practices_included_year = get_number_practices(df, end_date)['year']
    practices_included_months_3 = get_number_practices(df, end_date)['3_months']


    practices_included_percent_total = float(
        f'{((practices_included_total/num_practices)*100):.2f}')
    
    practices_included_percent_year = float(
        f'{((practices_included_year/num_practices)*100):.2f}')

    practices_included_percent_months_3 = float(
        f'{((practices_included_months_3/num_practices)*100):.2f}')


    return {"total": {"number": practices_included_total, "percent": practices_included_percent_total}, "year": {"number": practices_included_year, "percent": practices_included_percent_year}, "months_3": {"number": practices_included_months_3, "percent": practices_included_percent_months_3}}
    
    practices_included_total, practices_included_percent_total, practices_included_months_3, practices_included_percent_months_3


def calculate_statistics_demographics(df, demographic_var, end_date, event_column):

    end_date = datetime.datetime.strptime(
        end_date, '%Y-%m-%d')

    year_before = end_date - relativedelta(years=1)
    months_3_before = end_date - relativedelta(months=3)

    categories = df[demographic_var].unique()

    output_dict = {}
    for category in categories:
        df_subset_total = df[df[demographic_var] == category]
        events_total = df_subset_total[event_column].sum()
        
        df_subset_year = df[df['date'] > year_before]
        events_year = df_subset_year[event_column].sum()

        df_subset_months_3 = df[df['date'] > months_3_before]
        events_months_3 = df_subset_months_3[event_column].sum()

        output_dict[category] = {"total": events_total, "year": events_year, "months_3": events_months_3}
    
    counts_df = pd.DataFrame.from_dict(output_dict, orient='index')
    counts_df = counts_df.rename(columns={"total": "Total Study Period", "year": "Within Last Year", "months_3": "Within Last 3 Months"})
    return counts_df

def interactive_deciles_chart(
    df,
    period_column=None,
    column=None,
    title="",
    ylabel=""
):
    """period_column must be dates / datetimes
    """

    df = add_percentiles(
        df,
        period_column=period_column,
        column=column,
        show_outer_percentiles=False,
    )

    fig = go.Figure()

    

    for percentile in np.unique(df['percentile']):
        df_subset = df[df['percentile'] == percentile]
        if percentile == 50:
            fig.add_trace(go.Scatter(x=df_subset[period_column], y=df_subset[column], line={
                          "color": "blue", "dash": "solid", "width": 1.2}, name="median"))
        else:
            fig.add_trace(go.Scatter(x=df_subset[period_column], y=df_subset[column], line={
                          "color": "blue", "dash": "dash", "width": 1}, name=f"decile {int(percentile/10)}"))

     # Set title
    fig.update_layout(
        title_text=title,
        hovermode='x',
        title_x=0.5,


    )

    fig.update_yaxes(title=ylabel)
    fig.update_xaxes(title="Date")

    # Add range slider
    fig.update_layout(
        xaxis=go.layout.XAxis(
            rangeselector=dict(
                buttons=list([
                    dict(count=1,
                         label="1m",
                         step="month",
                         stepmode="backward"),
                    dict(count=6,
                         label="6m",
                         step="month",
                         stepmode="backward"),

                    dict(count=1,
                         label="1y",
                         step="year",
                         stepmode="backward"),
                    dict(step="all")
                ])
            ),
            rangeslider=dict(
                visible=True
            ),
            type="date"
        )
    )

    fig.show()


