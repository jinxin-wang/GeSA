rule overlap_exom_bed_with_targets:
    input:
        exom_bed = config["bcftools"][config["samples"]]["exom_bed"],
        targets = config["targeted"]["target"],
    output:
        bed_for_mutect2 = config["targeted"]["bed_for_mutect2"],
    log:
        out = "logs/targeted/overlap_exom_bed_with_targets.log",
    params:
        queue = "shortq",
    threads : 1
    resources:
        mem_mb = 10240
    run:

        logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.DEBUG)

        import pandas as pd
        import numpy as np

        def is_ict(t1,t2):
            if t1[0] <= t2[0] and t1[1] >= t2[0] :
                if  t1[1] >= t2[1] :
                    return 1
                else:
                    return 2
            if t2[0] <= t1[0] and t2[1] >= t1[0] :
                if t2[1] >= t1[1] :
                    return 3
                else:
                    return 4
            return 0

        def merge_interval(tp,t1,t2):
            if tp == 1:
                return t1
            elif tp == 2:
                return [t1[0],t2[1]]
            elif tp == 3:
                return t2
            elif tp == 4:
                return [t2[0],t1[1]]

        def sort_df(df):
            return df.groupby(['chr'], group_keys=False).apply(lambda x : x.sort_values(['start'])).reset_index(drop=True)

        def merge_all_targets(sorted_targets_df):
            merged_targets = []
            merged_row     = []

            for ridx, row in sorted_targets_df.iterrows():
                if ridx == 0 :
                    merged_row = [row['chr'], row['start'], row['end']]
                    continue ;

                prev_row = sorted_targets_df.iloc[ridx-1]

                if row['chr'] != prev_row['chr'] :
                    merged_targets.append(merged_row)
                    merged_row = [row['chr'], row['start'], row['end']]
                    continue

                t1 = [merged_row[1], merged_row[2]]
                t2 = [row['start'], row['end']]
                tp = is_ict(t1,t2)

                if tp > 0:
                    merged_row[1:3] = merge_interval(tp, t1, t2)
                else :
                    merged_targets.append(merged_row)
                    merged_row = [row['chr'], row['start'], row['end']]

            return sort_df(pd.DataFrame(merged_targets, columns=['chr','start','end']))

        def bed_intersect_with_targets(bed_df, targets_df):
            isin = np.zeros(len(bed_df))
            for ridx, target_row in targets_df.iterrows():
                t1 = [target_row['start'], target_row['end']]
                isin = isin + bed_df.map(lambda x : 0 if x['chr'] != target_row['chr'] else is_ict(t1,[x['start'],x['end']]))
            return bed_df[isin>0].reset_index(drop=True)

        padded_df = pd.read_table(input.exom_bed, names=['chr','start','end'])
        targets_df = pd.read_table(input.targets, names=['chr','start','end','gene'])

        if 'chr' in targets_df['chr'].iloc[0].lower() : # then it's 0-base, change to 1-base
            targets_df['chr'] = targets_df['chr'].map(lambda x : x.lower().replace('chr', ''))
            targets_df['start'] = targets_df['start'] - 1

        merged_targets_df = merge_all_targets(sort_df(targets_df))

        targeted_padded_df = bed_intersect_with_targets(padded_df, targets_df)
        targeted_padded_df.to_csv(output.bed_for_mutect2, sep='\t', header=False, index=False)

